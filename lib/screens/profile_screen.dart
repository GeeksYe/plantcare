import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'garden_screen.dart';
import 'care_calendar_screen.dart';
import 'reminder_settings_screen.dart';
import 'encyclopedia_screen.dart';
import 'about_screen.dart';
import 'profile_edit_screen.dart';

/// 一级页：我的（头像信息卡 + 三等分数据 + 常用功能列表，数据来自本机）
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _store = LocalStore.instance;

  String? _avatarPath;
  String _avatarEmoji = '🌿';
  String _name = '小满';
  String _bio = '';
  String _activeBadge = '';
  int _careDays = 0;
  int _checkinDays = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _avatarPath = _store.userAvatarPath;
    _avatarEmoji = _store.userAvatarEmoji;
    _name = _store.userName;
    _bio = _store.userBio;
    _activeBadge = _store.activeBadge;
    _careDays = _store.careDays;
    _checkinDays = _store.checkinDays;
    if (mounted) setState(() {});
  }

  UserBadge? get _wornBadge {
    if (_activeBadge.isEmpty) return null;
    for (final b in MockData.badges) {
      if (b.id == _activeBadge) return b;
    }
    return null;
  }

  Future<void> _openEdit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
    if (changed == true) _load();
  }

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
    final badge = _wornBadge;
    return GestureDetector(
      onTap: _openEdit,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          UserAvatar(imagePath: _avatarPath, emoji: _avatarEmoji, size: 58),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(_name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Color(badge.colorValue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('${badge.emoji} ${badge.name}',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(badge.colorValue),
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
              const SizedBox(height: 5),
              Text(
                _bio.isEmpty
                    ? '养护第 $_careDays 天 · 与 ${MockData.plants.length} 株绿植为伴'
                    : _bio,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.sub),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.sub),
        ]),
      ),
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
        _stat('$_careDays', '养护天数'),
        _stat('${MockData.plants.length}', '植物数'),
        _stat('$_checkinDays', '连续打卡'),
      ]),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
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
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.sub),
          ]),
        ),
      ),
    );
  }
}
