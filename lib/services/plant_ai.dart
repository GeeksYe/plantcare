import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/disease_kb.dart';
import '../data/species_kb.dart';
import '../services/local_store.dart';

/// AI 诊断结果
class AiDiagnosis {
  final String name; // 病害名 / 植物名
  final double score; // 置信度 0~1
  final String? latin; // 学名（植物识别时可能有）
  final String summary; // 症状 / 简介描述
  final String level; // 轻度 / 中度 / 重度 / 健康 / 物种
  final List<String> solutions; // 解决方案 / 养护要点
  final String source; // cloud（云端 AI） / local（本地知识库）
  final String? sourceNote; // 说明，如接口错误原因
  final String? baikeUrl;
  final String kind; // disease / species
  final List<Map<String, String>> alternatives; // 其他候选（name + score%）

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
    this.kind = 'disease',
    this.alternatives = const [],
  });

  bool get isCloud => source == 'cloud';
}

enum AiTask { disease, species }

/// 候选（内部用）
class _Cand {
  final String name;
  final double score;
  final Map<String, dynamic>? baike;
  _Cand(this.name, this.score, this.baike);
}

/// 真实 AI 病虫害检测 / 植物识别服务
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
      return _localResult(hint, task: task);
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
        return _localResult(hint,
            task: task, note: '云端识别失败：$lastErr，已切换本地知识库');
      }

      if (task == AiTask.species) return _parseSpecies(data);
      return _parseDisease(data, hint);
    } catch (e) {
      return _localResult(hint,
          task: task, note: '云端调用异常（$e），已切换本地知识库');
    }
  }

  // ---------- 病虫害检测 ----------
  AiDiagnosis _parseDisease(Map<String, dynamic> data, String hint) {
    final list = (data['result'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) {
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
        kind: 'disease',
        sourceNote: '如仍有异常，可拍叶背特写再次识别',
      );
    }

    // 按置信度降序排列
    final cands = list
        .map((e) {
          final name = (e['name'] ?? '未知') as String;
          final score = ((e['score'] as num?)?.toDouble() ?? 0.0)
              .clamp(0.0, 1.0)
              .toDouble();
          return _Cand(name, score, e['baike_info'] as Map<String, dynamic>?);
        })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // 优先用「明确指向某病害」的强映射（不再受症状串污染）
    for (final c in cands) {
      final kb = DiseaseKb.matchByName(c.name);
      if (kb != null) {
        return AiDiagnosis(
          name: kb['name'] as String,
          score: c.score,
          summary: kb['symptom'] as String,
          level: kb['level'] as String,
          solutions:
              (kb['solutions'] as List).map((e) => '$e').toList(),
          source: 'cloud',
          kind: 'disease',
          sourceNote: '云端 AI 识别「${c.name}」· 方案来自养护知识库',
          alternatives: _alts(cands, c.name),
        );
      }
    }

    // 未命中本地库：置信度足够则按云端名给出通用方案；否则低置信度提示
    final top = cands.first;
    if (top.score >= 0.5) {
      final desc = (top.baike?['description'] as String?) ?? '';
      return AiDiagnosis(
        name: top.name,
        score: top.score,
        summary: desc.isNotEmpty
            ? desc
            : '云端识别到「${top.name}」，建议结合植株实际症状采取通用处理。',
        level: '中度',
        solutions: DiseaseKb.genericSolutions,
        source: 'cloud',
        kind: 'disease',
        sourceNote: desc.isNotEmpty ? '描述来自百度百科' : null,
        alternatives: _alts(cands, top.name),
      );
    }

    // 低置信度：展示候选，让用户确认或重拍，避免强行给结论（尤其防误判铁黄叶）
    return AiDiagnosis(
      name: '识别置信度较低',
      score: top.score,
      summary:
          '云端对这张照片的病害判断置信度偏低（最高约 ${(top.score * 100).toStringAsFixed(0)}%），可能是角度、光照或病征尚不明显。下方列出最可能的几种情况供对照，建议拍摄对焦清晰、病斑明显的叶正反面再试。',
      level: '轻度',
      solutions: const [
        '重新拍摄：对焦病斑，光线充足、背景简洁',
        '尽量同时拍叶正面与叶背',
        '可结合下方“补充症状”手动辅助判断',
      ],
      source: 'cloud',
      kind: 'disease',
      sourceNote: '低置信度结果，仅供参考',
      alternatives: _alts(cands, null),
    );
  }

  // ---------- 植物识别 ----------
  AiDiagnosis _parseSpecies(Map<String, dynamic> data) {
    final list = (data['result'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) {
      return AiDiagnosis(
        name: '未能识别该植物',
        score: 0.4,
        summary: '云端未识别出植物物种，建议拍摄植物整体株型与叶片特写，光线充足、背景简洁。',
        level: '物种',
        solutions: const [
          '重新拍摄：展示完整株型与叶片',
          '尽量拍清晰、无遮挡',
          '尝试不同角度多拍一张',
        ],
        source: 'cloud',
        kind: 'species',
        sourceNote: '未识别到物种',
      );
    }

    final cands = list
        .map((e) {
          final name = (e['name'] ?? '未知') as String;
          final score = ((e['score'] as num?)?.toDouble() ?? 0.0)
              .clamp(0.0, 1.0)
              .toDouble();
          return _Cand(name, score, e['baike_info'] as Map<String, dynamic>?);
        })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final top = cands.first;
    final care = SpeciesKb.byName(top.name);
    final desc = (top.baike?['description'] as String?) ?? '';
    final baikeUrl = top.baike?['baike_url'] as String?;

    final solutions = care != null
        ? <String>[
            '光照：${care['light']}',
            '浇水：${care['water']}',
            '养护：${care['tip']}',
          ]
        : (desc.isNotEmpty
            ? [desc]
            : DiseaseKb.speciesGeneric);

    return AiDiagnosis(
      name: top.name,
      score: top.score,
      latin: care?['latin'] as String?,
      summary: care != null
          ? (care['intro'] as String)
          : (desc.isNotEmpty
              ? desc
              : '已识别为「${top.name}」，可据此查询该植物的光照与浇水需求。'),
      level: '物种',
      solutions: solutions,
      source: 'cloud',
      kind: 'species',
      sourceNote: care != null ? '养护要点来自本地物种库' : '描述来自百度百科',
      baikeUrl: baikeUrl,
      alternatives: _alts(cands, top.name),
    );
  }

  /// 取除命中项外的前 3 个候选（name + score%）
  List<Map<String, String>> _alts(List<_Cand> cands, String? exclude) {
    final out = <Map<String, String>>[];
    for (final c in cands) {
      if (exclude != null && c.name == exclude) continue;
      out.add({
        'name': c.name,
        'score': (c.score * 100).toStringAsFixed(0),
      });
      if (out.length >= 3) break;
    }
    return out;
  }

  /// 本地知识库兜底（未配置云端时）
  AiDiagnosis _localResult(String hint,
      {String? note, AiTask task = AiTask.disease}) {
    if (task == AiTask.species) {
      return AiDiagnosis(
        name: '未配置 AI，无法识别物种',
        score: 0.0,
        summary:
            '未配置百度智能云 API，植物识别需调用云端模型。请先在 AI 页右上「接入 AI」填入 API Key / Secret Key，或切换到病虫害检测使用本地知识库。',
        level: '物种',
        solutions: const ['在 AI 页右上「接入 AI」填入百度智能云 API Key / Secret Key'],
        source: 'local',
        kind: 'species',
        sourceNote: note,
      );
    }
    final kb = DiseaseKb.match(hint);
    if (kb != null) {
      return AiDiagnosis(
        name: kb['name'] as String,
        score: 0.72,
        summary: kb['symptom'] as String,
        level: kb['level'] as String,
        solutions: (kb['solutions'] as List).map((e) => '$e').toList(),
        source: 'local',
        kind: 'disease',
        sourceNote: note,
      );
    }
    return AiDiagnosis(
      name: '待确认的叶片异常',
      score: 0.5,
      summary: '根据你选择的症状仍无法精确判定，可按下列通用方案处理，或接入云端 AI 获取更准判断。',
      level: '轻度',
      solutions: DiseaseKb.genericSolutions,
      source: 'local',
      kind: 'disease',
      sourceNote: note,
    );
  }
}
