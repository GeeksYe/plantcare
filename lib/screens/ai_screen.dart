import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/mock_data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 一级页：AI 识别（调用系统相机拍照 + 绿植看病诊断；识别结果为本地 mock，接服务器时替换）
class AiScreen extends StatefulWidget {
  const AiScreen({super.key});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  bool _scanning = false;
  bool _showResult = false;
  int _mode = 0; // 0 识别植物 1 看病诊断
  String? _photoPath; // 拍摄/选择的照片路径
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const Text('AI 植物助手',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text('拍一拍，认识你的绿色邻居',
              style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
          const SizedBox(height: 16),
          _modeSwitch(),
          const SizedBox(height: 16),
          _scanner(),
          const SizedBox(height: 10),
          _galleryEntry(),
          if (_showResult) ..._resultCards(),
          const SizedBox(height: 6),
          SectionTitle('最近识别'),
          ...MockData.wikiEntries.take(3).map(_historyItem),
        ],
      ),
    );
  }

  Widget _modeSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        _modeTab('识别植物', Icons.center_focus_weak, 0),
        _modeTab('绿植看病', Icons.healing, 1),
      ]),
    );
  }

  Widget _modeTab(String label, IconData icon, int index) {
    final selected = _mode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _mode = index; _showResult = false; _photoPath = null; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 17,
                color: selected ? AppColors.forest : AppColors.sub),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: selected ? AppColors.forest : AppColors.sub)),
          ]),
        ),
      ),
    );
  }

  Widget _scanner() {
    return GestureDetector(
      onTap: _scan,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.softCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Stack(children: [
            Center(
              child: _scanning
                  ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: AppColors.forest),
                      SizedBox(height: 12),
                      Text('AI 正在识别中…',
                          style: TextStyle(fontSize: 13, color: AppColors.forest, fontWeight: FontWeight.w600)),
                    ])
                  : _photoPath != null
                      ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_photoPath!),
                                width: 200, height: 200, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 10),
                          Text(_showResult ? '点击重新拍摄' : '已获取照片，分析中…',
                              style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
                        ])
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.photo_camera_outlined, size: 46, color: AppColors.forest),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                                _mode == 0 ? 'assets/images/monstera.png' : 'assets/images/ficus.png',
                                width: 120, height: 90, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 10),
                          Text(_mode == 0 ? '对准植物，点击调起相机拍照' : '拍下有问题的叶片',
                              style: const TextStyle(fontSize: 13.5, color: AppColors.sub)),
                        ]),
            ),
            // 取景框四角
            ..._corners(),
          ]),
        ),
      ),
    );
  }

  List<Widget> _corners() {
    const size = 26.0, w = 3.0, pad = 18.0;
    final color = AppColors.forest;
    return [
      Positioned(top: pad, left: pad, child: _corner(size, w, color, top: true, left: true)),
      Positioned(top: pad, right: pad, child: _corner(size, w, color, top: true, left: false)),
      Positioned(bottom: pad, left: pad, child: _corner(size, w, color, top: false, left: true)),
      Positioned(bottom: pad, right: pad, child: _corner(size, w, color, top: false, left: false)),
    ];
  }

  Widget _corner(double size, double w, Color color, {required bool top, required bool left}) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _CornerPainter(color: color, w: w, top: top, left: left, radius: 12)),
    );
  }

  /// 点击取景框：调起系统相机拍照（用户取消则不触发分析）
  Future<void> _scan() async {
    if (_scanning) return;
    final XFile? photo = await _pick(ImageSource.camera);
    if (photo == null) return;
    await _analyze(photo);
  }

  /// 从相册选择照片识别
  Future<void> _pickFromGallery() async {
    if (_scanning) return;
    final XFile? photo = await _pick(ImageSource.gallery);
    if (photo == null) return;
    await _analyze(photo);
  }

  Future<XFile?> _pick(ImageSource source) async {
    try {
      return await _picker.pickImage(
          source: source, maxWidth: 1200, imageQuality: 85);
    } catch (_) {
      return null;
    }
  }

  Future<void> _analyze(XFile photo) async {
    setState(() { _photoPath = photo.path; _scanning = true; _showResult = false; });
    await Future.delayed(const Duration(milliseconds: 1600));
    setState(() { _scanning = false; _showResult = true; });
  }

  Widget _galleryEntry() {
    return GestureDetector(
      onTap: _pickFromGallery,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.photo_library_outlined, size: 16, color: AppColors.forest),
          SizedBox(width: 6),
          Text('从相册选择照片识别',
              style: TextStyle(fontSize: 12.5, color: AppColors.forest, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  List<Widget> _resultCards() {
    if (_mode == 0) {
      return [
        SoftCard(
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _resultThumb(76, 56),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('龟背竹', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                SizedBox(height: 2),
                Text('Monstera deliciosa · 天南星科',
                    style: TextStyle(fontSize: 11.5, color: AppColors.sub, fontStyle: FontStyle.italic)),
                SizedBox(height: 4),
                Text('置信度 98.2% · 喜散射光，耐阴',
                    style: TextStyle(fontSize: 12, color: AppColors.emerald, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        SoftCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('养护要点', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            SizedBox(height: 8),
            Text('• 明亮散射光，避免暴晒\n• 土干 2cm 再浇透\n• 每月擦拭叶面，助「开背」\n• 冬季保持 10℃ 以上',
                style: TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.7)),
          ]),
        ),
        const SizedBox(height: 6),
      ];
    }
    return [
      SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _resultThumb(76, 56),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('诊断结果：叶斑病（早期）',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                SizedBox(height: 4),
                Text('危险程度：轻微 · 置信度 91.4%',
                    style: TextStyle(fontSize: 12, color: AppColors.amber, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const Divider(height: 20),
          const Text('用药建议',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('1. 剪除病叶并销毁，避免传染\n2. 喷施多菌灵 800 倍液，每 7 天一次，连续 2~3 次\n3. 改善通风，浇水避开叶面',
              style: TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.7)),
        ]),
      ),
      const SizedBox(height: 6),
    ];
  }

  /// 结果卡缩略图：优先展示实拍照片，无照片时回退到示例图
  Widget _resultThumb(double w, double h) {
    if (_photoPath != null) {
      return Image.file(File(_photoPath!), width: w, height: h, fit: BoxFit.cover);
    }
    return Image.asset(
        _mode == 0 ? 'assets/images/monstera.png' : 'assets/images/ficus.png',
        width: w, height: h, fit: BoxFit.cover);
  }

  Widget _historyItem(entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(entry.image, width: 56, height: 42, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text(entry.latin, style: const TextStyle(fontSize: 11, color: AppColors.sub, fontStyle: FontStyle.italic)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.sub),
        ]),
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
