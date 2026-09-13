import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'garden_screen.dart';
import 'care_calendar_screen.dart';
import 'reminder_settings_screen.dart';
import 'encyclopedia_screen.dart';
import 'about_screen.dart';

/// 一级页：我的（数据等分 + 常用功能入口）
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LocalStore.instance;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(children: [
            const EmojiAvatar('👩‍🌾', size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('地主的花园',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                SizedBox(height: 3),
                Text(' lvl.4 · 用心园丁 · 已坚持养护 368 天',
                    style: TextStyle(fontSize: 12, color: AppColors.sub)),
              ]),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.settings_outlined, color: AppColors.sub),
            ),
          ]),
          const SizedBox(height: 16),
          // 数据四等分
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              _stat('368', '养护天数'),
              _divider(),
              _stat('4', '植物数'),
              _divider(),
              _stat('1280', '积分'),
              _divider(),
              _stat('12', '成就'),
            ]),
          ),
          const SizedBox(height: 16),
          _levelCard(),
          const SizedBox(height: 16),
          SectionTitle('常用'),
          _menu(Icons.local_florist_outlined, '我的花园', '查看全部植物与最近动态',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GardenScreen()))),
          _menu(Icons.calendar_month_outlined, '养护日历', '每周任务安排与完成情况',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CareCalendarScreen()))),
          _menu(Icons.notifications_outlined, '提醒设置', '浇水/施肥/光照提醒与免打扰',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderSettingsScreen()))),
          _menu(Icons.menu_book_outlined, '植物百科', '养护知识与热门问答',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EncyclopediaScreen()))),
          _menu(Icons.info_outline, '关于我们', '版本信息与反馈渠道',
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
          const SizedBox(height: 16),
          // 缓存提示
          SoftCard(
            child: Row(children: [
              const Icon(Icons.cloud_off_outlined, size: 18, color: AppColors.sub),
              const SizedBox(width: 8),
              Expanded(
                child: Text('离线模式：昵称、打卡、设置等数据已缓存到本机',
                    style: TextStyle(fontSize: 11.5, color: AppColors.sub, height: 1.4)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(value,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.forest)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
        ]),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 32, color: AppColors.border);

  Widget _levelCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.military_tech, size: 18, color: AppColors.forest),
          SizedBox(width: 6),
          Text('养护等级 Lv.4 · 用心园丁',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          Spacer(),
          Text('1280 / 1600',
              style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const LinearProgressIndicator(
            value: 0.8, minHeight: 8,
            backgroundColor: Colors.white,
            color: AppColors.emerald,
          ),
        ),
        const SizedBox(height: 6),
        const Text('再获 320 积分升级 Lv.5，解锁礼品兑换商城',
            style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
      ]),
    );
  }

  Widget _menu(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: onTap,
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.softCard, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: AppColors.forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.sub),
        ]),
      ),
    );
  }
}
