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
  final String speak; // 语音播报文案

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
    this.speak = '',
  });

  bool get isCloud => source == 'cloud';
}

enum AiTask { disease, species }

/// 候选（植物识别用，含百度百科）
class _Cand {
  final String name;
  final double score;
  final Map<String, dynamic>? baike;
  _Cand(this.name, this.score, this.baike);
}

/// 真实 AI 病虫害检测 / 植物识别服务
/// - 病虫害检测：阿里云百炼 Qwen-VL 多模态大模型（看照片即可诊断病害/虫害/生理问题）
/// - 植物识别：百度智能云 plant 物种模型
/// - 两套独立密钥入口：disease→Qwen-VL（单一 DashScope Key）、species→百度 AK/SK
/// - 未配置或调用失败：自动降级到本地知识库给出方案
class PlantAiService {
  PlantAiService._();
  static final PlantAiService instance = PlantAiService._();

  // 百度（植物识别用）
  static const _tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const _plantUrl =
      'https://aip.baidubce.com/rest/2.0/image-classify/v1/plant';

  // 阿里云百炼 Qwen-VL 多模态
  static const _qwenUrl =
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation';
  static const _qwenModel = 'qwen-vl-max';

  static const _timeout = Duration(seconds: 40);

  String? _token;
  DateTime? _tokenExpire;
  String? _tokenAk; // 记录该 token 对应的 API Key，避免两套不同密钥串号
  final _store = LocalStore.instance;

  /// 病虫害检测是否已配置 Qwen-VL
  bool get diseaseConfigured => _store.qwenApiKey.isNotEmpty;

  /// 植物识别是否已配置百度 AK/SK
  bool get speciesConfigured =>
      _store.speciesApiKey.isNotEmpty && _store.speciesSecretKey.isNotEmpty;

  /// 任一已配置（兼容旧逻辑）
  bool get configured => diseaseConfigured || speciesConfigured;

  void resetToken() {
    _token = null;
    _tokenExpire = null;
    _tokenAk = null;
  }

  /// 百度 access_token（按传入的 AK/SK，按密钥缓存避免串号）
  Future<String?> _accessToken(String ak, String sk) async {
    if (ak.isEmpty || sk.isEmpty) return null;
    if (_token != null &&
        _tokenAk == ak &&
        _tokenExpire != null &&
        DateTime.now().isBefore(_tokenExpire!)) {
      return _token;
    }
    final uri = Uri.parse(
        '$_tokenUrl?grant_type=client_credentials&client_id=$ak&client_secret=$sk');
    final resp = await http.post(uri).timeout(_timeout);
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (data['error'] != null || data['access_token'] == null) {
      throw Exception(data['error_description'] ?? '获取 access_token 失败');
    }
    _token = data['access_token'] as String;
    _tokenAk = ak;
    final exp = (data['expires_in'] as num?)?.toInt() ?? 2592000;
    _tokenExpire = DateTime.now().add(Duration(seconds: exp - 300));
    return _token;
  }

  /// 分析图片：disease=病虫害检测（Qwen-VL），species=植物识别（百度）
  Future<AiDiagnosis> analyze(File image,
      {AiTask task = AiTask.disease, String hint = ''}) async {
    if (task == AiTask.disease) return _analyzeDisease(image, hint);

    // ---------- 植物识别（百度 plant）----------
    final ak = _store.speciesApiKey;
    final sk = _store.speciesSecretKey;
    if (ak.isEmpty || sk.isEmpty) {
      return _localResult(hint, task: task);
    }
    try {
      final token = await _accessToken(ak, sk);
      if (token == null) return _localResult(hint, task: task);
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      final body = <String, String>{'image': b64, 'baike_num': '1'};
      final resp = await http
          .post(Uri.parse('$_plantUrl?access_token=$token'),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: body)
          .timeout(_timeout);
      final data = jsonDecode(resp.body);
      if (data is Map<String, dynamic> && data['error_code'] == null) {
        return _parseSpecies(data);
      }
      return _localResult(hint,
          task: task,
          note: '云端识别失败：${data['error_msg'] ?? data['error_code']}，已切换本地知识库');
    } catch (e) {
      return _localResult(hint,
          task: task, note: '云端调用异常（$e），已切换本地知识库');
    }
  }

  // ---------- 病虫害检测：Qwen-VL 多模态 ----------
  Future<AiDiagnosis> _analyzeDisease(File image, String hint) async {
    final r = await _tryQwen(image, hint);
    if (r != null) return r;
    return _localResult(hint, task: AiTask.disease);
  }

  /// 阿里云百炼 Qwen-VL：看照片诊断病害
  Future<AiDiagnosis?> _tryQwen(File image, String hint) async {
    final key = _store.qwenApiKey;
    if (key.isEmpty) return null;
    try {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      final imgUrl = 'data:image/jpeg;base64,$b64';
      final body = {
        'model': _qwenModel,
        'input': {
          'messages': [
            {
              'role': 'user',
              'content': [
                {'image': imgUrl},
                {'text': _qwenDiseasePrompt(hint)},
              ]
            }
          ]
        },
        'parameters': {
          'result_format': 'message',
          'temperature': 0.2,
        }
      };
      final resp = await http
          .post(
            Uri.parse(_qwenUrl),
            headers: {
              'Authorization': 'Bearer $key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      final data = jsonDecode(resp.body);
      // DashScope 错误结构：{ "code": "...", "message": "..." }
      if (data is Map<String, dynamic> &&
          data['output'] == null &&
          data['code'] != null) {
        final msg = data['message'] ?? data['code'];
        return _localResult(hint,
            task: AiTask.disease, note: 'Qwen-VL 调用失败：$msg，已切换本地知识库');
      }
      final text = _qwenText(data);
      if (text == null) {
        return _localResult(hint,
            task: AiTask.disease, note: 'Qwen-VL 返回解析失败，已切换本地知识库');
      }
      return _parseQwen(text, hint);
    } catch (e) {
      return _localResult(hint,
          task: AiTask.disease, note: 'Qwen-VL 调用异常（$e），已切换本地知识库');
    }
  }

  String? _qwenText(Map<String, dynamic> data) {
    final output = data['output'];
    if (output is! Map) return null;
    final choices = output['choices'];
    if (choices is! List || choices.isEmpty) return null;
    final msg = choices[0]['message'];
    if (msg is! Map) return null;
    final content = msg['content'];
    if (content is String) return content;
    if (content is List) {
      for (final c in content) {
        if (c is Map && c['text'] is String) return c['text'] as String;
      }
    }
    return null;
  }

  /// 从模型回复中尽量抽取 JSON 对象（模型可能夹带说明文字或 markdown）
  Map<String, dynamic>? _extractJson(String text) {
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final sub = text.substring(start, end + 1);
        final decoded = jsonDecode(sub);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {}
    return null;
  }

  String _qwenDiseasePrompt(String hint) {
    final hintLine = hint.isNotEmpty ? '用户补充症状：$hint。' : '';
    return '你是一名资深植物医生，专为家庭绿植（龟背竹、绿萝、虎皮兰、多肉、琴叶榕、发财树等）看诊。'
        '请仔细观察这张植物照片，$hintLine'
        '判断植株是否健康；若不健康，判断是病害（真菌/细菌/病毒）、虫害，还是生理性/环境问题（缺水、烂根、日灼、缺素黄叶等）。\n'
        '只返回一个 JSON 对象，不要 markdown 代码块、不要任何额外说明，格式严格如下：\n'
        '{\n'
        '  "healthy": true 或 false,\n'
        '  "isPlant": true 或 false,\n'
        '  "name": "病害/虫害中文名；健康则填「绿植健康」",\n'
        '  "category": "healthy | pest | fungal | virus | abiotic",\n'
        '  "level": "健康 | 轻度 | 中度 | 重度",\n'
        '  "summary": "一句话描述症状或健康状态",\n'
        '  "solutions": ["针对该问题的具体处理方案1", "方案2", "方案3"]\n'
        '}';
  }

  AiDiagnosis _parseQwen(String text, String hint) {
    final json = _extractJson(text);
    // 解析失败：退化为本地知识库，但保留"云端已分析"的语义
    if (json == null) {
      return _localResult(hint,
          task: AiTask.disease, note: 'Qwen-VL 返回为非结构化文本，已用本地知识库兜底');
    }

    final isPlant = json['isPlant'] != false;
    if (!isPlant) {
      return AiDiagnosis(
        name: '未检测到植物',
        score: 0.3,
        summary: '这张照片里似乎没有植物（可能是杂物或纯背景）。请拍摄清晰的叶片 / 植株照片再试。',
        level: '轻度',
        solutions: const [
          '重新拍摄：将植物叶片置于取景框中央',
          '保证光线充足、背景简洁',
          '尽量拍到异常部位特写',
        ],
        source: 'cloud',
        kind: 'disease',
        speak: '未检测到植物',
        sourceNote: 'Qwen-VL 判断图片不含植物',
      );
    }

    final healthy = json['healthy'] == true;
    final name = (json['name'] as String?)?.trim().isNotEmpty == true
        ? (json['name'] as String).trim()
        : (healthy ? '绿植健康' : '未明异常');
    final category = (json['category'] as String?) ?? '';
    final level = (json['level'] as String?)?.trim() ??
        (healthy ? '健康' : '轻度');
    final summary = (json['summary'] as String?)?.trim() ??
        (healthy ? '植株当前健康，未发现明显病害。' : '请结合实际情况处理。');

    var solutions = <String>[];
    final s = json['solutions'];
    if (s is List) {
      for (final e in s) {
        if (e is String && e.trim().isNotEmpty) solutions.add(e.trim());
      }
    }
    if (solutions.isEmpty) solutions = DiseaseKb.genericSolutions;

    return AiDiagnosis(
      name: name,
      score: healthy ? 0.92 : 0.78,
      summary: summary,
      level: level,
      solutions: solutions,
      source: 'cloud',
      kind: 'disease',
      speak: _qwenSpeak(name, category, healthy),
      sourceNote: 'Qwen-VL 多模态判断',
      alternatives: const [],
    );
  }

  /// 病虫害语音播报：极简状态词
  static String _qwenSpeak(String name, String category, bool healthy) {
    if (healthy) return '绿植健康';
    if (category == 'pest' || name.contains('虫')) return '绿植生虫';
    if (category == 'fungal' ||
        category == 'virus' ||
        name.contains(RegExp(r'病|霉|斑'))) {
      return '绿植生病';
    }
    if (category == 'abiotic' || name.contains('黄')) return '绿植叶黄';
    if (name.contains(RegExp(r'腐|烂|枯'))) return '绿植烂根';
    return '绿植异常';
  }

  // ---------- 植物识别（百度，原逻辑保留）----------
  AiDiagnosis _parseSpecies(Map<String, dynamic> data) {
    final list =
        (data['result'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (list.isEmpty) {
      return AiDiagnosis(
        name: '未能识别该植物',
        score: 0.4,
        summary:
            '云端未识别出植物物种，建议拍摄植物整体株型与叶片特写，光线充足、背景简洁。',
        level: '物种',
        solutions: const [
          '重新拍摄：展示完整株型与叶片',
          '尽量拍清晰、无遮挡',
          '尝试不同角度多拍一张',
        ],
        source: 'cloud',
        kind: 'species',
        speak: _speciesSpeak(''),
        sourceNote: '未识别到物种',
      );
    }

    final cands = list
        .map((e) {
          final name = (e['name'] ?? '未知') as String;
          final score =
              ((e['score'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0).toDouble();
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
        : (desc.isNotEmpty ? [desc] : DiseaseKb.speciesGeneric);

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
      speak: _speciesSpeak(top.name),
      sourceNote: care != null ? '养护要点来自本地物种库' : '描述来自百度百科',
      baikeUrl: baikeUrl,
      alternatives: _alts(cands, top.name),
    );
  }

  /// 取除命中项外的前 3 个候选（name + score%）
  List<Map<String, String>> _alts(List<_Cand> cands, String exclude) {
    final out = <Map<String, String>>[];
    for (final c in cands) {
      if (c.name == exclude) continue;
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
            '未配置植物识别的云端 API，请先在 AI 页右上「接入 AI」中填写「植物识别」专用的 API Key / Secret Key。',
        level: '物种',
        solutions: const ['在 AI 页右上「接入 AI」填写植物识别专用密钥'],
        source: 'local',
        kind: 'species',
        speak: '未配置植物识别，无法播报',
        sourceNote: note,
      );
    }
    // 病虫害：提示接入 Qwen-VL
    final kb = DiseaseKb.match(hint);
    if (kb != null) {
      final name = kb['name'] as String;
      final level = kb['level'] as String;
      return AiDiagnosis(
        name: name,
        score: 0.72,
        summary: kb['symptom'] as String,
        level: level,
        solutions: (kb['solutions'] as List).map((e) => '$e').toList(),
        source: 'local',
        kind: 'disease',
        speak: _qwenSpeak(name, '', false),
        sourceNote: note,
      );
    }
    return AiDiagnosis(
      name: '待确认的叶片异常',
      score: 0.5,
      summary:
          '根据你选择的症状仍无法精确判定，可按下列通用方案处理，或接入 Qwen-VL 云端 AI 获取更准判断。',
      level: '轻度',
      solutions: DiseaseKb.genericSolutions,
      source: 'local',
      kind: 'disease',
      speak: '绿植状态待确认',
      sourceNote: note,
    );
  }

  /// 植物识别：播报「这是薄荷」
  static String _speciesSpeak(String name) =>
      name.isEmpty ? '未能识别该植物' : '这是$name';
}
