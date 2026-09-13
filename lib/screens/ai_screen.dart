import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';

/// 一级页：AI 植物识别（对齐设计稿：深绿相机卡 + 识别结果卡 + 绿植看病卡）
/// 相机/相册为真实调用，识别结论为本地 mock，接服务器时替换 _analyze
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  bool _scanning = false;
  bool _showResult = false;
  String? _photoPath;
  final ImagePicker _picker = ImagePicker();
  final _symptoms = <String>{};

  static const _symptomOptions = ['叶片发黄', '烂根发臭', '虫害斑点', '生长缓慢'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          _header(),
          const SizedBox(height: 14),
          _cameraCard(),
          if (_showResult) ...[
            const SizedBox(height: 14),
            _resultCard(),
          ],
          const SizedBox(height: 14),
          _diagnoseCard(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(children: [
      const Text('AI 植物识别',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const Spacer(),
      GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('拍下植物清晰照片，AI 自动识别物种并给出养护建议'),
            backgroundColor: AppColors.forest)),
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: const Text('?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sub)),
        ),
      ),
    ]);
  }

  // ---------- 相机卡 ----------

  Widget _cameraCard() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF15803D)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: [
        const Text('将植物放入取景框',
            style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Expanded(child: _viewfinder()),
        const SizedBox(height: 12),
        Row(children: [
          _camSideButton(Icons.photo_library_outlined, _pickFromGallery),
          const Spacer(),
          _shutter(),
          const Spacer(),
          _camSideButton(Icons.cameraswitch_outlined, () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('已切换摄像头（演示）'), backgroundColor: AppColors.forest));
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
        height: 230,
        child: Stack(children: [
          if (hasPhoto)
            Center(
              child: Opacity(
                opacity: _scanning ? 0.5 : 1.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_photoPath!), width: 220, height: 190, fit: BoxFit.cover),
                ),
              ),
            )
          else
            const Center(child: Icon(Icons.eco_outlined, size: 72, color: Color(0x3DFFFFFF))),
          ..._corners(),
          if (_scanning)
            const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 10),
                Text('AI 正在识别中…',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ]),
            ),
        ]),
      ),
    );
  }

  List<Widget> _corners() {
    const size = 30.0, w = 3.5;
    const color = Color(0xFFF59E0B); // 设计稿的橙色取景角
    return [
      Positioned(top: 0, left: 16, child: _corner(size, w, color, top: true, left: true)),
      Positioned(top: 0, right: 16, child: _corner(size, w, color, top: true, left: false)),
      Positioned(bottom: 0, left: 16, child: _corner(size, w, color, top: false, left: true)),
      Positioned(bottom: 0, right: 16, child: _corner(size, w, color, top: false, left: false)),
    ];
  }

  Widget _corner(double size, double w, Color color, {required bool top, required bool left}) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _CornerPainter(color: color, w: w, top: top, left: left, radius: 10)),
    );
  }

  Widget _shutter() {
    return GestureDetector(
      onTap: _scan,
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 3),
        ),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: const BoxDecoration(color: Color(0xFF166534), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: _scanning
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _camSideButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: const BoxDecoration(color: Color(0x29FFFFFF), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: Colors.white),
      ),
    );
  }

  // ---------- 拍照与识别 ----------

  Future<void> _scan() async {
    if (_scanning) return;
    final XFile? photo = await _pick(ImageSource.camera);
    if (photo == null) return;
    await _analyze(photo);
  }

  Future<void> _pickFromGallery() async {
    if (_scanning) return;
    final XFile? photo = await _pick(ImageSource.gallery);
    if (photo == null) return;
    await _analyze(photo);
  }

  Future<XFile?> _pick(ImageSource source) async {
    try {
      return await _picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
    } catch (_) {
      return null;
    }
  }

  Future<void> _analyze(XFile photo) async {
    setState(() { _photoPath = photo.path; _scanning = true; _showResult = false; });
    await Future.delayed(const Duration(milliseconds: 1600));
    setState(() { _scanning = false; _showResult = true; });
  }

  // ---------- 识别结果卡 ----------

  Widget _resultCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          const Text('识别结果',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('已识别 · 98%',
                style: TextStyle(fontSize: 11, color: AppColors.emerald, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),
        const Text('龟背竹',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 2),
        const Text('Monstera deliciosa',
            style: TextStyle(fontSize: 12, color: AppColors.sub, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: const LinearProgressIndicator(
              value: 0.98, minHeight: 6,
              backgroundColor: AppColors.softCard, color: AppColors.forest),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 42,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('龟背竹：喜散射光，土干 2cm 浇透，每月擦叶助「开背」'),
                backgroundColor: AppColors.forest)),
            child: const Text('查看养护详情', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  // ---------- 绿植看病卡 ----------

  Widget _diagnoseCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('绿植看病',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
        const SizedBox(height: 4),
        const Text('描述症状，AI帮你诊断病害',
            style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _symptomOptions.map(_symptomChip).toList(),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 42,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
            ),
            onPressed: _diagnose,
            child: const Text('开始 AI 诊断', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
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
            style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.sub)),
      ),
    );
  }

  void _diagnose() {
    if (_symptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('请先选择至少一个症状'), backgroundColor: AppColors.forest));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('诊断结果：叶斑病（早期）',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('危险程度：轻微 · 置信度 91.4%',
                style: TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w600)),
            const Divider(height: 22),
            const Text('用药建议',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('1. 剪除病叶并销毁，避免传染\n2. 喷施多菌灵 800 倍液，每 7 天一次，连续 2~3 次\n3. 改善通风，浇水避开叶面',
                style: TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.7)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 42,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('知道了', style: TextStyle(fontSize: 13.5)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double w;
  final bool top;
  final bool left;
  final double radius;
  _CornerPainter({required this.color, required this.w, required this.top, required this.left, required this.radius});

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
