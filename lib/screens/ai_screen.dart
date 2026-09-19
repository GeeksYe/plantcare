import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/local_store.dart';
import '../services/media_store.dart';
import '../services/plant_ai.dart';
import '../theme.dart';

/// 一级页：AI 植物医生（真实相机 + 云端病虫害 AI 检测 + 解决方案）
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _picker = ImagePicker();
  final _ai = PlantAiService.instance;
  final _store = LocalStore.instance;
  final _tts = FlutterTts();
  final _symptoms = <String>{};

  bool _scanning = false;
  bool _ttsReady = false;
  String? _photoPath;
  AiDiagnosis? _result;
  AiTask _task = AiTask.disease;

  static const _symptomOptions = [
    '叶片发黄',
    '烂根发臭',
    '虫害斑点',
    '白粉霉层',
    '叶片卷曲',
    '生长缓慢'
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    } catch (_) {}
  }

  /// 语音播报（识别完成后自动念出，也可点扬声器重读）
  Future<void> _speak(String text) async {
    if (text.isEmpty || !_ttsReady) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          _header(),
          const SizedBox(height: 12),
          _modeSwitch(),
          const SizedBox(height: 10),
          _configStatusRow(),
          const SizedBox(height: 12),
          _cameraCard(),
          if (_task == AiTask.disease && !_ai.diseaseConfigured) ...[
            const SizedBox(height: 12),
            _configBanner('病虫害检测'),
          ],
          if (_task == AiTask.species && !_ai.speciesConfigured) ...[
            const SizedBox(height: 12),
            _configBanner('植物识别'),
          ],
          if (_result != null) ...[
            const SizedBox(height: 14),
            _resultCard(_result!),
          ],
          if (_task == AiTask.disease) ...[
            const SizedBox(height: 14),
            _symptomCard(),
          ],
          const SizedBox(height: 14),
          _historyCard(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      const Text('AI 植物医生',
          style: TextStyle(
              fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const Spacer(),
      GestureDetector(
        onTap: _configSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Icon(Icons.settings_outlined,
                size: 15,
                color: _ai.diseaseConfigured && _ai.speciesConfigured
                    ? AppColors.emerald
                    : (_ai.diseaseConfigured || _ai.speciesConfigured
                        ? AppColors.amber
                        : AppColors.sub)),
            const SizedBox(width: 4),
            Text(
                _ai.diseaseConfigured && _ai.speciesConfigured
                    ? 'AI 已接入'
                    : (_ai.diseaseConfigured || _ai.speciesConfigured
                        ? '部分接入'
                        : '接入 AI'),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _ai.diseaseConfigured && _ai.speciesConfigured
                        ? AppColors.emerald
                        : (_ai.diseaseConfigured || _ai.speciesConfigured
                            ? AppColors.amber
                            : AppColors.sub))),
          ]),
        ),
      ),
    ]);
  }

  Widget _modeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _modeItem('病虫害检测', Icons.coronavirus_outlined, AiTask.disease),
        _modeItem('植物识别', Icons.yard_outlined, AiTask.species),
      ]),
    );
  }

  /// 两套 AI 接入状态概览（各自独立密钥）
  Widget _configStatusRow() {
    final items = [
      ('病虫害检测', _ai.diseaseConfigured),
      ('植物识别', _ai.speciesConfigured),
    ];
    return Row(
      children: items
          .map((e) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: e == items.first ? 8 : 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    Icon(
                        e.$2
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        size: 14,
                        color: e.$2 ? AppColors.emerald : AppColors.sub),
                    const SizedBox(width: 5),
                    Text(e.$1,
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: e.$2 ? AppColors.ink : AppColors.sub)),
                    const Spacer(),
                    Text(e.$2 ? '已接入' : '未接入',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: e.$2 ? AppColors.emerald : AppColors.amber)),
                  ]),
                ),
              ))
          .toList(),
    );
  }

  Widget _modeItem(String label, IconData icon, AiTask task) {
    final selected = _task == task;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _task = task;
          _result = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.forest : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppColors.sub),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.sub)),
          ]),
        ),
      ),
    );
  }

  // ---------- 相机卡 ----------
  Widget _cameraCard() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF15803D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        Text(
            _task == AiTask.disease
                ? '拍下病叶 / 异常部位，AI 自动检测病害'
                : '将植物放入取景框，AI 自动识别物种',
            style: const TextStyle(
                color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Expanded(child: _viewfinder()),
        const SizedBox(height: 12),
        Row(children: [
          _camSideButton(Icons.photo_library_outlined, _pickFromGallery),
          const Spacer(),
          _shutter(),
          const Spacer(),
          _camSideButton(Icons.history, () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('检测记录已保存 ${_store.aiHistory.length} 条'),
                backgroundColor: AppColors.forest));
          }),
        ]),
      ]),
    );
  }

  Widget _viewfinder() {
    final hasPhoto = _photoPath != null;
    return Center(
      child: SizedBox(
        width: double.infinity,
        height: 210,
        child: Stack(children: [
          if (hasPhoto)
            Center(
              child: Opacity(
                opacity: _scanning ? 0.45 : 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_photoPath!),
                      width: 210, height: 180, fit: BoxFit.cover),
                ),
              ),
            )
          else
            Center(
              child: Icon(
                  _task == AiTask.disease
                      ? Icons.coronavirus_outlined
                      : Icons.eco_outlined,
                  size: 68,
                  color: const Color(0x3DFFFFFF)),
            ),
          ..._corners(),
          if (_scanning)
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 10),
                Text(
                    (_task == AiTask.disease
                            ? _ai.diseaseConfigured
                            : _ai.speciesConfigured)
                        ? '已上传，AI 正在云端分析…'
                        : 'AI 正在分析中…',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      ),
    );
  }

  List<Widget> _corners() {
    const size = 30.0, w = 3.5;
    const color = Color(0xFFF59E0B);
    return [
      Positioned(top: 0, left: 16, child: _corner(size, w, color, top: true, left: true)),
      Positioned(top: 0, right: 16, child: _corner(size, w, color, top: true, left: false)),
      Positioned(bottom: 0, left: 16, child: _corner(size, w, color, top: false, left: true)),
      Positioned(bottom: 0, right: 16, child: _corner(size, w, color, top: false, left: false)),
    ];
  }

  Widget _corner(double size, double w, Color color,
      {required bool top, required bool left}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
          painter:
              _CornerPainter(color: color, w: w, top: top, left: left, radius: 10)),
    );
  }

  Widget _shutter() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 3),
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: const BoxDecoration(
              color: Color(0xFF166534), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: _scanning
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.4))
              : const Icon(Icons.photo_camera, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _camSideButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
            color: Color(0x29FFFFFF), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: Colors.white),
      ),
    );
  }

  // ---------- 拍照 / 上传 / 检测 ----------
  Future<void> _takePhoto() async {
    if (_scanning) return;
    final photo =
        await _picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 85);
    if (photo == null) return;
    await _runAi(photo);
  }

  Future<void> _pickFromGallery() async {
    if (_scanning) return;
    final photo =
        await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (photo == null) return;
    await _runAi(photo);
  }

  Future<void> _runAi(XFile photo) async {
    setState(() {
      _photoPath = photo.path;
      _scanning = true;
      _result = null;
    });

    // 持久化照片，避免系统清理临时文件
    String saved = photo.path;
    try {
      saved = await MediaStore.save(photo.path, kind: 'ai');
    } catch (_) {}

    final hint = _symptoms.join('、');
    final result = await _ai.analyze(File(saved), task: _task, hint: hint);

    await _store.addAiHistory({
      'name': result.name,
      'score': result.score,
      'level': result.level,
      'source': result.source,
      'task': _task == AiTask.disease ? '病虫害检测' : '植物识别',
      'photo': saved,
      'time': DateTime.now().millisecondsSinceEpoch,
    });

    if (!mounted) return;
    setState(() {
      _scanning = false;
      _result = result;
    });
    _speak(result.speak);
  }

  // ---------- 配置 ----------
  Widget _configBanner(String taskName) {
    return GestureDetector(
      onTap: _configSheet,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(children: [
          const Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text('未配置「$taskName」云端 AI，当前用本地方案。点此接入真实 $taskName 模型',
                style: const TextStyle(fontSize: 12, color: AppColors.amber, height: 1.4)),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.amber),
        ]),
      ),
    );
  }

  void _configSheet() {
    // 病虫害检测：阿里云百炼 Qwen-VL（单一 DashScope API Key）
    // 植物识别：百度 plant（AK/SK）
    final qAk = TextEditingController(text: _store.qwenApiKey);
    final sAk = TextEditingController(text: _store.speciesApiKey);
    final sSk = TextEditingController(text: _store.speciesSecretKey);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('接入真实 AI（两套独立密钥）',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 8),
              const Text(
                '病虫害检测使用阿里云百炼 Qwen-VL 多模态大模型（看照片即可诊断，国内手机号注册阿里云即得）；植物识别使用百度智能云（手机号注册）。两者独立配置，互不干扰。',
                style: TextStyle(fontSize: 12, color: AppColors.sub, height: 1.6)),
              const SizedBox(height: 14),
              _keySection(
                '病虫害检测 AI（Qwen-VL 多模态）',
                '阿里云百炼 API Key（sk- 开头，单一密钥即可，无需 Secret）',
                qAk,
                TextEditingController(),
                _ai.diseaseConfigured,
                showSecret: false,
              ),
              const SizedBox(height: 14),
              _keySection(
                '植物识别 AI（百度 plant）',
                '识别植物叫什么',
                sAk,
                sSk,
                _ai.speciesConfigured,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    await _store.setQwenApiKey(qAk.text);
                    await _store.setSpeciesApiKey(sAk.text);
                    await _store.setSpeciesSecretKey(sSk.text);
                    _ai.resetToken();
                    if (!mounted) return;
                    Navigator.pop(context);
                    setState(() {});
                    final msg = _ai.diseaseConfigured && _ai.speciesConfigured
                        ? '已保存，病虫害与植物识别均接入云端'
                        : (_ai.diseaseConfigured || _ai.speciesConfigured
                            ? '已保存，部分 AI 已接入（未填的仍用本地方案）'
                            : '已清空配置，使用本地知识库');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(msg), backgroundColor: AppColors.forest));
                  },
                  child: const Text('保存配置',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// 单个密钥配置分组（标题 + 两句说明 + AK/SK 输入 + 状态）
  /// [showSecret] = false 时只显示 API Key（如 Qwen-VL 单一密钥）
  Widget _keySection(String title, String subtitle, TextEditingController ak,
      TextEditingController sk, bool configured,
      {bool showSecret = true}) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: configured
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(configured ? '已接入' : '未接入',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: configured ? AppColors.emerald : AppColors.amber)),
          ),
        ]),
        const SizedBox(height: 3),
        Text(subtitle,
            style: const TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.4)),
        const SizedBox(height: 10),
        _input(ak, 'API Key'),
        if (showSecret) ...[
          const SizedBox(height: 9),
          _input(sk, 'Secret Key'),
        ],
      ]),
    );
  }

  Widget _input(TextEditingController c, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: c,
        style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.sub),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  // ---------- 结果 ----------
  Widget _resultCard(AiDiagnosis r) {
    final levelColor = r.level == '重度'
        ? const Color(0xFFDC2626)
        : (r.level == '中度' ? AppColors.amber : AppColors.emerald);
    final pct = (r.score * 100).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('检测报告',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const Spacer(),
          if (r.speak.isNotEmpty)
            GestureDetector(
              onTap: () => _speak(r.speak),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.softCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.volume_up_outlined,
                    size: 16, color: AppColors.emerald),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: r.isCloud ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(r.isCloud ? '云端 AI · $pct%' : '本地知识库',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: r.isCloud ? AppColors.emerald : AppColors.amber)),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: Text(r.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text('${r.level}',
                style: TextStyle(
                    fontSize: 11.5, color: levelColor, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: r.score.clamp(0.0, 1.0).toDouble(),
            minHeight: 6,
            backgroundColor: AppColors.softCard,
            color: r.isCloud ? AppColors.forest : AppColors.amber,
          ),
        ),
        const SizedBox(height: 4),
        Text('置信度 $pct%',
            style: const TextStyle(fontSize: 11, color: AppColors.sub)),
        if (r.summary.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('症状表现',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(r.summary,
              style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.65)),
        ],
        if (r.alternatives.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('其他可能',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: r.alternatives
                .map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.softCard,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${a['name']} · ${a['score']}%',
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.sub, fontWeight: FontWeight.w600)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Icon(r.kind == 'species' ? Icons.eco_outlined : Icons.healing_outlined,
              size: 16, color: AppColors.emerald),
          const SizedBox(width: 5),
          Text(r.kind == 'species' ? '养护要点' : '解决方案',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ]),
        const SizedBox(height: 6),
        for (var i = 0; i < r.solutions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('${i + 1}',
                    style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.solutions[i],
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.ink, height: 1.55)),
              ),
            ]),
          ),
        if (r.sourceNote != null) ...[
          const SizedBox(height: 8),
          Text(r.sourceNote!,
              style: const TextStyle(fontSize: 11, color: AppColors.sub)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
            ),
            onPressed: () => setState(() => _result = null),
            child: const Text('重新检测',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  // ---------- 症状辅助 ----------
  Widget _symptomCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('补充症状（可选）',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 4),
        const Text('选择症状可辅助 AI 判断，未配置服务时据此匹配本地知识库',
            style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _symptomOptions.map(_symptomChip).toList(),
        ),
      ]),
    );
  }

  Widget _symptomChip(String s) {
    final selected = _symptoms.contains(s);
    return GestureDetector(
      onTap: () => setState(() => selected ? _symptoms.remove(s) : _symptoms.add(s)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.forest : AppColors.border),
        ),
        child: Text(s,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.sub)),
      ),
    );
  }

  // ---------- 历史 ----------
  Widget _historyCard() {
    final list = _store.aiHistory;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('检测记录',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const Spacer(),
          if (list.isNotEmpty)
            GestureDetector(
              onTap: () async {
                await _store.clearAiHistory();
                setState(() {});
              },
              child: const Text('清空',
                  style: TextStyle(fontSize: 12, color: AppColors.sub)),
            ),
        ]),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Text('还没有检测记录，拍一张叶片试试吧～',
              style: TextStyle(fontSize: 12.5, color: AppColors.sub))
        else
          for (final h in list.take(5)) _historyItem(h),
      ]),
    );
  }

  Widget _historyItem(Map<String, dynamic> h) {
    final name = (h['name'] ?? '') as String;
    final score = ((h['score'] ?? 0) as num).toDouble();
    final source = (h['source'] ?? 'local') as String;
    final ts = (h['time'] ?? 0) as int;
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final timeStr = '${d.month}月${d.day}日 ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: source == 'cloud'
                ? AppColors.emerald.withValues(alpha: 0.12)
                : AppColors.amber.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(source == 'cloud' ? Icons.cloud_done_outlined : Icons.storage_outlined,
              size: 17, color: source == 'cloud' ? AppColors.emerald : AppColors.amber),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
            Text('$timeStr · ${h['task']}',
                style: const TextStyle(fontSize: 11, color: AppColors.sub)),
          ]),
        ),
        Text('${(score * 100).toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: AppColors.sub)),
      ]),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double w;
  final bool top;
  final bool left;
  final double radius;
  _CornerPainter(
      {required this.color,
      required this.w,
      required this.top,
      required this.left,
      required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - radius);
      path.quadraticBezierTo(0, size.height, radius, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}
