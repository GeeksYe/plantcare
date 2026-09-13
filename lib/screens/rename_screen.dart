import 'package:flutter/material.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 三级页：修改植物昵称（保存到本地缓存）
class RenameScreen extends StatefulWidget {
  final Plant plant;
  const RenameScreen({super.key, required this.plant});

  @override
  State<RenameScreen> createState() => _RenameScreenState();
}

class _RenameScreenState extends State<RenameScreen> {
  late final TextEditingController _controller;
  final store = LocalStore.instance;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: store.nicknameOf(widget.plant.id, widget.plant.defaultNickname));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    await store.setNickname(widget.plant.id, name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('已保存，它现在叫「$name」啦 🌿'),
        backgroundColor: AppColors.forest,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plant;
    return Scaffold(
      appBar: const PageHeader('修改昵称'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Center(
            child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(p.image, width: 96, height: 72, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              Text(p.species, style: const TextStyle(fontSize: 13, color: AppColors.sub)),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('给它取一个喜欢的名字吧',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLength: 12,
            autofocus: true,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: '例如：皮卡丘',
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('昵称会显示在首页、我的花园和详情页',
              style: TextStyle(fontSize: 12, color: AppColors.sub)),
          const SizedBox(height: 24),
          PrimaryButton('保存昵称', icon: Icons.check, onTap: _save),
        ],
      ),
    );
  }
}
