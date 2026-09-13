import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 二级页：关于我们
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader('关于我们'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Center(
            child: Column(children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.forest, AppColors.emerald]),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.local_florist, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              const Text('绿植管家',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 4),
              const Text('Version 1.0.0 · Build 1',
                  style: TextStyle(fontSize: 12, color: AppColors.sub)),
              const SizedBox(height: 6),
              const Text('让每一盆绿植都被温柔以待',
                  style: TextStyle(fontSize: 12.5, color: AppColors.emerald, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 20),
          SectionTitle('核心功能'),
          _feature('🪴', '智能花盆互联', '湿度 / 温度 / 光照实时监测，一键浇水'),
          _feature('📸', 'AI 识别与看病', '拍照识别植物，早期病害诊断与用药建议'),
          _feature('🌏', '养花人社区', '分享成长记录，交流养护心得'),
          const SizedBox(height: 16),
          SectionTitle('更多'),
          _linkRow(Icons.feedback_outlined, '意见反馈', () {}),
          _linkRow(Icons.privacy_tip_outlined, '隐私政策', () {}),
          _linkRow(Icons.description_outlined, '用户协议', () {}),
          const SizedBox(height: 24),
          const Center(
            child: Text('© 2026 绿植管家 GreenMate · 离线演示版',
                style: TextStyle(fontSize: 11, color: AppColors.sub)),
          ),
        ],
      ),
    );
  }

  Widget _feature(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _linkRow(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: onTap,
        child: Row(children: [
          Icon(icon, size: 19, color: AppColors.forest),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
          const Icon(Icons.chevron_right, color: AppColors.sub),
        ]),
      ),
    );
  }
}
