import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/disease_kb.dart';
import '../services/local_store.dart';

/// AI 诊断结果
class AiDiagnosis {
  final String name; // 病害名 / 植物名
  final double score; // 置信度 0~1
  final String? latin; // 学名（植物识别时可能有）
  final String summary; // 症状 / 简介描述
  final String level; // 轻度 / 中度 / 重度 / 健康
  final List<String> solutions; // 解决方案
  final String source; // cloud（云端 AI） / local（本地知识库）
  final String? sourceNote; // 说明，如接口错误原因
  final String? baikeUrl;

  const AiDiagnosis({
    required this.name,
    required this.score,
    this.latin,
    required this.summary,
    required this.level,
    required this.solutions,
    required this.source,
    this.sourceNote,
    this.baikeUrl,
  });

  bool get isCloud => source == 'cloud';
}

enum AiTask { disease, species }

/// 真实 AI 病虫害检测服务
/// - 已配置百度智能云 AK/SK：调用云端图像识别（植物病害 / 植物识别）
/// - 未配置或调用失败：自动降级到本地病害知识库给出方案
class PlantAiService {
  PlantAiService._();
  static final PlantAiService instance = PlantAiService._();

  static const _tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const _diseaseUrl =
      'https://aip.baidubce.com/rest/2.0/image-classify/v1/plant-disease';
  static const _diseaseUrlAlt =
      'https://aip.baidubce.com/rest/2.0/image-classify/v1/plant_disease';
  static const _plantUrl =
      'https://aip.baidubce.com/rest/2.0/image-classify/v1/plant';

  static const _timeout = Duration(seconds: 30);

  String? _token;
  DateTime? _tokenExpire;
  final _store = LocalStore.instance;

  bool get configured =>
      _store.aiApiKey.isNotEmpty && _store.aiSecretKey.isNotEmpty;

  void resetToken() {
    _token = null;
    _tokenExpire = null;
  }

  Future<String?> _accessToken() async {
    if (_token != null &&
        _tokenExpire != null &&
        DateTime.now().isBefore(_tokenExpire!)) {
      return _token;
    }
    final uri = Uri.parse(
        '$_tokenUrl?grant_type=client_credentials&client_id=${_store.aiApiKey}&client_secret=${_store.aiSecretKey}');
    final resp = await http.post(uri).timeout(_timeout);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['error'] != null || data['access_token'] == null) {
      throw Exception(data['error_description'] ?? '获取 access_token 失败');
    }
    _token = data['access_token'] as String;
    final exp = (data['expires_in'] as num?)?.toInt() ?? 2592000;
    _tokenExpire = DateTime.now().add(Duration(seconds: exp - 300));
    return _token;
  }

  /// 分析图片：disease=病虫害检测，species=植物识别
  Future<AiDiagnosis> analyze(File image,
      {AiTask task = AiTask.disease, String hint = ''}) async {
    if (!configured) {
      return _localResult(hint.isEmpty ? '未配置 AI 服务' : hint,
          note: '未配置百度智能云 API，当前使用本地病害知识库');
    }
    try {
      final token = await _accessToken();
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      final body = <String, String>{'image': b64, 'baike_num': '1'};
      final headers = <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final urls = task == AiTask.disease
          ? <String>[_diseaseUrl, _diseaseUrlAlt]
          : <String>[_plantUrl];

      Map<String, dynamic>? data;
      String? lastErr;
      for (final url in urls) {
        final resp = await http
            .post(Uri.parse('$url?access_token=$token'),
                headers: headers, body: body)
            .timeout(_timeout);
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded['error_code'] != null) {
            lastErr = '${decoded['error_code']} ${decoded['error_msg']}';
            continue;
          }
          data = decoded;
          break;
        }
      }
      if (data == null) {
        return _localResult(hint, note: '云端识别失败：$lastErr，已切换本地知识库');
      }

      final result = (data['result'] as List?)?.cast<Map<String, dynamic>>();
      if (result == null || result.isEmpty) {
        // 未识别出病害，可能是健康植株
        return AiDiagnosis(
          name: '未发现明显病害',
          score: 0.6,
          summary: '云端模型未在这张照片中检测到典型病害特征，植株看起来比较健康。',
          level: '健康',
          solutions: const [
            '继续保持当前光照与浇水节奏',
            '每周检查一次叶背，早发现早处理',
            '保持通风，避免盆内长期积水',
          ],
          source: 'cloud',
          sourceNote: '如仍有异常，可拍叶背特写再次识别',
        );
      }

      final first = result.first;
      final name = (first['name'] ?? '未知') as String;
      final score = ((first['score'] as num?)?.toDouble() ?? 0.0)
          .clamp(0.0, 1.0)
          .toDouble();
      final baike = first['baike_info'] as Map<String, dynamic>?;
      final description = (baike?['description'] as String?) ?? '';
      final baikeUrl = baike?['baike_url'] as String?;

      final kb = DiseaseKb.match('$name $hint');
      if (kb != null) {
        return AiDiagnosis(
          name: '${kb['name']}',
          score: score,
          summary: kb['symptom'] as String,
          level: kb['level'] as String,
          solutions: (kb['solutions'] as List).map((e) => '$e').toList(),
          source: 'cloud',
          sourceNote: '云端 AI 识别 · 方案来自养护知识库',
          baikeUrl: baikeUrl,
        );
      }

      return AiDiagnosis(
        name: name,
        score: score,
        summary: description.isNotEmpty
            ? description
            : '云端识别到「$name」，建议结合症状采取以下措施。',
        level: task == AiTask.disease ? '中度' : '健康',
        solutions: task == AiTask.disease
            ? DiseaseKb.genericSolutions
            : const [
                '根据识别结果查询该植物的光照需求',
                '遵循“见干见湿”浇水原则',
                '生长季每月施一次薄肥',
              ],
        source: 'cloud',
        sourceNote: description.isNotEmpty ? '描述来自百度百科' : null,
        baikeUrl: baikeUrl,
      );
    } catch (e) {
      return _localResult(hint, note: '云端调用异常（$e），已切换本地知识库');
    }
  }

  /// 本地知识库兜底
  AiDiagnosis _localResult(String hint, {String? note}) {
    final kb = DiseaseKb.match(hint);
    if (kb != null) {
      return AiDiagnosis(
        name: kb['name'] as String,
        score: 0.72,
        summary: kb['symptom'] as String,
        level: kb['level'] as String,
        solutions: (kb['solutions'] as List).map((e) => '$e').toList(),
        source: 'local',
        sourceNote: note,
      );
    }
    return AiDiagnosis(
      name: '待确认的叶片异常',
      score: 0.5,
      summary: '根据你选择的症状，暂时无法精确判定病害类型，可按下列通用方案处理。',
      level: '轻度',
      solutions: DiseaseKb.genericSolutions,
      source: 'local',
      sourceNote: note,
    );
  }
}
