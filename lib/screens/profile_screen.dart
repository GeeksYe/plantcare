import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'garden_screen.dart';
import 'care_calendar_screen.dart';
import 'reminder_settings_screen.dart';
import 'encyclopedia_screen.dart';
import 'about_screen.dart';

/// 一级页：我的（对齐设计稿：头像信息卡 + 三等分数据 + 常用功能列表）
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _userCard(),
          const SizedBox(height: 14),
          _statsCard(),
          const SizedBox(height: 18),
          const SectionTitle('常用'),
          const SizedBox(height: 10),
          _menu(Icons.local_florist_outlined, '我的花园',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GardenScreen()))),
          _menu(Icons.calendar_month_outlined, '养护日历',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareCalendarScreen()))),
          _menu(Icons.notifications_outlined, '提醒设置',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()))),
          _menu(Icons.menu_book_outlined, '植物百科',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EncyclopediaScreen()))),
          _menu(Icons.info_outline, '关于我们',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
        ],
      ),
    );
  }

  Widget _userCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Text('我的头像',
              style: TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('小满',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text('🌱 绿植达人',
                    style: TextStyle(fontSize: 10, color: AppColors.amber, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 5),
            Text('养护第 128 天 · 与 ${MockData.plants.length} 株绿植为伴',
                style: const TextStyle(fontSize: 12, color: AppColors.sub)),
          ]),
        ),
      ]),
    );
  }

  Widget _statsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _stat('128', '养护天数'),
        _stat('${MockData.plants.length}', '植物数'),
        _stat('36', '连续打卡'),
      ]),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
      ),
    );
  }

  Widget _menu(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.forest),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.sub),
          ]),
        ),
      ),
    );
  }
}
