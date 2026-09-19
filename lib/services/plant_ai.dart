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

/// 候选（plant.id 病害用，含类别与详情）
class _DiseaseCand {
  final String name;
  final double score;
  final String category;
  final Map<String, dynamic>? details;
  _DiseaseCand(this.name, this.score, this.category, this.details);
}

/// 真实 AI 病虫害检测 / 植物识别服务
/// - 病虫害检测：plant.id health_assessment（专为家庭绿植训练，识别病害/虫害/缺素/环境不适）
/// - 植物识别：百度智能云 plant 物种模型
/// - 两套独立密钥入口：disease→plant.id（单一 API Key）、species→百度 AK/SK
/// - 未配置或调用失败：自动降级到本地知识库给出方案
class PlantAiService {
  PlantAiService._();
  static final PlantAiService instance = PlantAiService._();

  // 百度（植物识别用）
  static const _tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const _plantUrl =
      'https://aip.baidubce.com/rest/2.0/image-classify/v1/plant';

  // plant.id（病虫害检测用）
  static const _plantIdHost = 'https://api.plant.id/v3/health_assessment';

  static const _timeout = Duration(seconds: 30);

  String? _token;
  DateTime? _tokenExpire;
  String? _tokenAk; // 记录该 token 对应的 API Key，避免两套不同密钥串号
  final _store = LocalStore.instance;

  /// 病虫害检测是否已配置 plant.id 密钥
  bool get diseaseConfigured => _store.plantIdKey.isNotEmpty;

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

  /// 分析图片：disease=病虫害检测（plant.id），species=植物识别（百度）
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

  // ---------- 病虫害检测（plant.id health_assessment）----------
  Future<AiDiagnosis> _analyzeDisease(File image, String hint) async {
    final key = _store.plantIdKey;
    if (key.isEmpty) {
      return _localResult(hint, task: AiTask.disease);
    }
    try {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      final uri = Uri.parse(
        '$_plantIdHost'
        '?language=zh'
        '&details=local_name,description,url,treatment,classification,common_names,cause',
      );
      final resp = await http
          .post(
            uri,
            headers: {
              'Api-Key': key,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'images': [b64],
              'similar_images': false,
            }),
          )
          .timeout(_timeout);
      final data = jsonDecode(resp.body);
      if (data is! Map<String, dynamic>) {
        return _localResult(hint,
            task: AiTask.disease, note: '云端返回异常，已切换本地知识库');
      }
      if (data['error'] != null || data['status'] == 'FAILED') {
        final err = data['error'] is Map
            ? (data['error']['message'] ?? data['error']['code'])
            : data['error'];
        return _localResult(hint,
            task: AiTask.disease, note: '云端识别失败：$err，已切换本地知识库');
      }
      return _parsePlantIdHealth(data, hint);
    } catch (e) {
      return _localResult(hint,
          task: AiTask.disease, note: '云端调用异常（$e），已切换本地知识库');
    }
  }

  AiDiagnosis _parsePlantIdHealth(Map<String, dynamic> data, String hint) {
    final result = data['result'] as Map<String, dynamic>?;
    final isPlant = (result?['is_plant'] as Map?) ?? {};
    final isPlantBin = isPlant['binary'] == true;
    final isHealthy = (result?['is_healthy'] as Map?) ?? {};
    final isHealthyBin = isHealthy['binary'] == true;
    final isHealthyProb =
        ((isHealthy['probability'] as num?)?.toDouble()) ?? 0.0;

    if (!isPlantBin) {
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
        sourceNote: 'plant.id 判断图片不含植物',
      );
    }

    // disease 字段可能是数组（直接 suggestions）或对象（含 suggestions）
    final diseaseField = result?['disease'];
    List<Map<String, dynamic>> suggestions;
    if (diseaseField is List) {
      suggestions = diseaseField.cast<Map<String, dynamic>>();
    } else if (diseaseField is Map) {
      suggestions =
          (diseaseField['suggestions'] as List?)?.cast<Map<String, dynamic>>() ??
              <Map<String, dynamic>>[];
    } else {
      suggestions = <Map<String, dynamic>>[];
    }

    if (isHealthyBin || suggestions.isEmpty) {
      return AiDiagnosis(
        name: '绿植健康',
        score: (1.0 - isHealthyProb).clamp(0.5, 1.0).toDouble(),
        summary: 'AI 判断植株当前健康，未发现明显病害。继续保持当前养护节奏即可。',
        level: '健康',
        solutions: const [
          '保持当前光照与浇水节奏',
          '每周检查一次叶背，早发现早处理',
          '保持通风，避免盆内长期积水',
        ],
        source: 'cloud',
        kind: 'disease',
        speak: '绿植健康',
        sourceNote: 'plant.id health：未检出病害',
      );
    }

    final cands = suggestions
        .map((e) {
          final name = (e['name'] ?? '未知') as String;
          final score =
              ((e['probability'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
          final category = (e['category'] as String?) ?? '';
          final details = e['details'] as Map<String, dynamic>?;
          return _DiseaseCand(name, score, category, details);
        })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final top = cands.first;
    final cnName = _plantIdName(top);
    final level = _probToLevel(top.score);
    final summary = _plantIdSummary(top);
    final solutions = _plantIdTreatment(top);

    return AiDiagnosis(
      name: cnName,
      score: top.score,
      summary: summary,
      level: level,
      solutions: solutions,
      source: 'cloud',
      kind: 'disease',
      speak: _diseaseSpeak(cnName, top.category, top.name),
      sourceNote: 'plant.id 识别：${top.name}',
      alternatives: _altsDisease(cands, top.name),
    );
  }

  /// plant.id 病害展示名：优先本地化中文名
  String _plantIdName(_DiseaseCand c) {
    final d = c.details;
    if (d != null) {
      final local = d['local_name'];
      if (local is String && local.isNotEmpty) return local;
      final common = d['common_names'];
      if (common is List && common.isNotEmpty) {
        final first = common.first;
        if (first is String && first.isNotEmpty) return first;
      }
    }
    return c.name; // 英文兜底
  }

  String _plantIdSummary(_DiseaseCand c) {
    final d = c.details;
    final desc = d?['description'];
    if (desc is String && desc.isNotEmpty) return desc;
    final catLabel = _categoryLabel(c.category);
    return 'AI 检测到「${c.name}」（$catLabel），置信度约 ${(c.score * 100).toStringAsFixed(0)}%。结合植株实际症状处理。';
  }

  static String _categoryLabel(String cat) {
    switch (cat) {
      case 'Fungi':
        return '真菌性病害';
      case 'Animalia':
        return '虫害';
      case 'Viruses':
        return '病毒性病害';
      case 'Abiotic':
        return '生理性/环境不适';
      case 'Senescence':
        return '自然老化';
      case 'Chromista':
        return '卵菌病害';
      default:
        return '植物病害';
    }
  }

  /// plant.id treatment 字段可能是字符串 / Map / List，统一抽取为方案列表
  List<String> _plantIdTreatment(_DiseaseCand c) {
    final t = c.details?['treatment'];
    final out = <String>[];
    if (t is String && t.isNotEmpty) {
      out.add(t);
    } else if (t is Map) {
      for (final v in t.values) {
        if (v is String && v.isNotEmpty) {
          out.add(v);
        } else if (v is List) {
          for (final item in v) {
            if (item is String && item.isNotEmpty) out.add(item);
          }
        }
      }
    } else if (t is List) {
      for (final item in t) {
        if (item is String && item.isNotEmpty) out.add(item);
      }
    }
    if (out.isEmpty) return DiseaseKb.genericSolutions;
    return out.take(6).toList();
  }

  static String _probToLevel(double p) {
    // plant.id 病害概率普遍偏低，按相对区间映射
    if (p >= 0.5) return '重度';
    if (p >= 0.25) return '中度';
    return '轻度';
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

  /// 病害候选前 3（按中文名展示）
  List<Map<String, String>> _altsDisease(
      List<_DiseaseCand> cands, String excludeRaw) {
    final out = <Map<String, String>>[];
    for (final c in cands) {
      if (c.name == excludeRaw) continue;
      out.add({
        'name': _plantIdName(c),
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
    // 病虫害：提示接入 plant.id
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
        speak: _diseaseSpeak(name, '', ''),
        sourceNote: note,
      );
    }
    return AiDiagnosis(
      name: '待确认的叶片异常',
      score: 0.5,
      summary:
          '根据你选择的症状仍无法精确判定，可按下列通用方案处理，或接入 plant.id 云端 AI 获取更准判断。',
      level: '轻度',
      solutions: DiseaseKb.genericSolutions,
      source: 'local',
      kind: 'disease',
      speak: '绿植状态待确认',
      sourceNote: note,
    );
  }

  // ---------- 语音播报文案 ----------
  /// 病虫害：用极简状态词播报，如「绿植健康」「绿植叶黄」「绿植生虫」
  static String _diseaseSpeak(String cnName, String category, String rawName) {
    if (cnName == '绿植健康') return '绿植健康';
    final raw = rawName.toLowerCase();
    if (category == 'Animalia' ||
        RegExp(r'mite|aphid|mealy|scale|thrip|whitefly|beetle|worm|pest|bug')
            .hasMatch(raw)) {
      return '绿植生虫';
    }
    if (category == 'Fungi' ||
        category == 'Viruses' ||
        category == 'Chromista' ||
        RegExp(r'mildew|blight|rust|botrytis|fungus|mold|spot|rot')
            .hasMatch(raw)) {
      return '绿植生病';
    }
    if (category == 'Abiotic' ||
        RegExp(r'deficien|burn|edema|overwater|drought|heat|cold|nutrient')
            .hasMatch(raw)) {
      return '绿植状态不佳';
    }
    if (category == 'Senescence') return '绿植老化';
    // 中文名关键词兜底
    if (cnName.contains('虫')) return '绿植生虫';
    if (cnName.contains(RegExp(r'病|霉|斑'))) return '绿植生病';
    if (cnName.contains('黄')) return '绿植叶黄';
    if (cnName.contains(RegExp(r'腐|烂|枯'))) return '绿植烂根';
    return '绿植异常';
  }

  /// 植物识别：播报「这是薄荷」
  static String _speciesSpeak(String name) =>
      name.isEmpty ? '未能识别该植物' : '这是$name';
}
