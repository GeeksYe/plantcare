import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../data/mock_data.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 二级页：个人资料设置（头像上传 + 资料编辑 + 勋章），全部数据存本机
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _store = LocalStore.instance;
  final _picker = ImagePicker();

  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _checkinCtrl = TextEditingController();

  String? _avatarPath;
  String _avatarEmoji = '🌿';
  String _gender = '未设置';
  DateTime _careStart = DateTime.now().subtract(const Duration(days: 128));
  List<String> _badges = const [];
  String _activeBadge = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _nameCtrl.text = _store.userName;
    _bioCtrl.text = _store.userBio;
    _cityCtrl.text = _store.userCity == '未设置' ? '' : _store.userCity;
    _checkinCtrl.text = '${_store.checkinDays}';
    _avatarPath = _store.userAvatarPath;
    _avatarEmoji = _store.userAvatarEmoji;
    _gender = _store.userGender;
    _careStart = _store.careStartDate;
    _badges = _store.badges;
    _activeBadge = _store.activeBadge;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _checkinCtrl.dispose();
    super.dispose();
  }

  // ---------------- 头像 ----------------
  Future<void> _pickAvatar(ImageSource source) async {
    final picked =
        await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 800);
    if (picked == null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final lower = picked.path.toLowerCase();
      var ext = '.jpg';
      for (final e in ['.jpg', '.jpeg', '.png', '.webp']) {
        if (lower.endsWith(e)) {
          ext = e;
          break;
        }
      }
      final target =
          '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
      await File(picked.path).copy(target);
      setState(() => _avatarPath = target);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('头像保存失败，请重试')));
      }
    }
  }

  void _avatarSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('更换头像',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 16),
          Row(children: [
            _sheetAction(Icons.photo_camera_outlined, '拍照', AppColors.forest,
                () {
              Navigator.pop(context);
              _pickAvatar(ImageSource.camera);
            }),
            const SizedBox(width: 12),
            _sheetAction(Icons.photo_library_outlined, '相册', AppColors.emerald,
                () {
              Navigator.pop(context);
              _pickAvatar(ImageSource.gallery);
            }),
            const SizedBox(width: 12),
            _sheetAction(Icons.emoji_emotions_outlined, '预设', AppColors.amber,
                () {
              Navigator.pop(context);
              _presetSheet();
            }),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _avatarPath = null);
              },
              child: Text('移除当前照片',
                  style: TextStyle(
                      fontSize: 14,
                      color: _avatarPath == null ? AppColors.sub : Colors.redAccent)),
            ),
          ),
          const SizedBox(height: 6),
          const Text('照片与资料均只保存在本机，不会上传服务器',
              style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
      ),
    );
  }

  void _presetSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('选择预设头像',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final e in MockData.presetAvatars)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _avatarEmoji = e;
                      _avatarPath = null;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.softCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _avatarEmoji == e && _avatarPath == null
                              ? AppColors.forest
                              : Colors.transparent,
                          width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(e, style: const TextStyle(fontSize: 28)),
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }

  Widget _sheetAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }

  // ---------------- 保存 ----------------
  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    await _store.setUserName(name);
    await _store.setUserBio(_bioCtrl.text);
    await _store.setUserCity(_cityCtrl.text.trim().isEmpty ? '未设置' : _cityCtrl.text.trim());
    await _store.setUserGender(_gender);
    await _store.setUserAvatarPath(_avatarPath);
    await _store.setUserAvatarEmoji(_avatarEmoji);
    await _store.setCareStartDate(_careStart);
    await _store.setCheckinDays(int.tryParse(_checkinCtrl.text) ?? 0);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('资料已保存到本机')));
    Navigator.pop(context, true);
  }

  // ---------------- 勋章 ----------------
  void _badgeDetail(UserBadge b) {
    final owned = _badges.contains(b.id);
    final color = Color(b.colorValue);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: owned ? color.withValues(alpha: 0.14) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: owned ? 1 : 0.35,
              child: Text(b.emoji, style: const TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(height: 12),
          Text(b.name,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('获得条件：${b.condition}',
              style: const TextStyle(fontSize: 13, color: AppColors.sub)),
          const SizedBox(height: 6),
          Text(
            owned
                ? (_store.badgeDate(b.id).isEmpty
                    ? '已获得'
                    : '获得于 ${_store.badgeDate(b.id)}')
                : '尚未解锁，继续养护即可获得',
            style: TextStyle(
                fontSize: 12.5,
                color: owned ? AppColors.emerald : AppColors.sub,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              owned
                  ? (_activeBadge == b.id ? '取消佩戴' : '佩戴到主页')
                  : '立即点亮（体验）',
              icon: owned ? Icons.verified_outlined : Icons.auto_awesome,
              color: owned ? AppColors.forest : AppColors.amber,
              onTap: () async {
                Navigator.pop(context);
                if (owned) {
                  await _store.setActiveBadge(_activeBadge == b.id ? '' : b.id);
                } else {
                  await _store.unlockBadge(b.id);
                }
                setState(() {
                  _badges = _store.badges;
                  _activeBadge = _store.activeBadge;
                });
              },
            ),
          ),
          if (owned) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _store.lockBadge(b.id);
                  setState(() {
                    _badges = _store.badges;
                    _activeBadge = _store.activeBadge;
                  });
                },
                child: const Text('移除该勋章',
                    style: TextStyle(fontSize: 13, color: AppColors.sub)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  // ---------------- 构建 ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: PageHeader('个人资料',
          action: TextButton(
            onPressed: _save,
            child: const Text('保存',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest)),
          )),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _avatarCard(),
          const SizedBox(height: 14),
          _infoCard(),
          const SizedBox(height: 14),
          _careCard(),
          const SizedBox(height: 18),
          const SectionTitle('我的勋章'),
          _badgeCard(),
          const SizedBox(height: 24),
          PrimaryButton('保存资料', icon: Icons.check_rounded, onTap: _save),
          const SizedBox(height: 10),
          const Center(
            child: Text('资料仅保存在本机，卸载应用后清除',
                style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
          ),
        ],
      ),
    );
  }

  Widget _avatarCard() {
    return SoftCard(
      child: Column(children: [
        GestureDetector(
          onTap: _avatarSheet,
          child: Stack(children: [
            UserAvatar(
                imagePath: _avatarPath, emoji: _avatarEmoji, size: 92),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        const Text('点击更换头像',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        if (_avatarPath != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _avatarPath = null),
            child: const Text('移除当前照片',
                style: TextStyle(fontSize: 12, color: Colors.redAccent)),
          ),
        ],
      ]),
    );
  }

  Widget _infoCard() {
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('昵称'),
        _field(_nameCtrl, '给自己起个名字'),
        const SizedBox(height: 14),
        _label('个人简介'),
        _field(_bioCtrl, '介绍一下你的绿植生活～', maxLines: 3),
        const SizedBox(height: 14),
        _label('性别'),
        const SizedBox(height: 8),
        Row(children: [
          for (final g in ['未设置', '女生', '男生'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(g, _gender == g, () => setState(() => _gender = g)),
            ),
        ]),
        const SizedBox(height: 14),
        _label('所在城市'),
        _field(_cityCtrl, '例如：杭州'),
      ]),
    );
  }

  Widget _careCard() {
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('养护开始日'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: _careStart,
              firstDate: DateTime(2010),
              lastDate: DateTime.now(),
            );
            if (d != null) setState(() => _careStart = d);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.event_outlined, size: 18, color: AppColors.emerald),
              const SizedBox(width: 8),
              Text(
                '${_careStart.year} 年 ${_careStart.month} 月 ${_careStart.day} 日',
                style: const TextStyle(fontSize: 14, color: AppColors.ink),
              ),
              const Spacer(),
              Text('已养护 ${DateTime.now().difference(_careStart).inDays} 天',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.forest,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        _label('连续打卡天数'),
        _field(_checkinCtrl, '例如：36', numeric: true),
      ]),
    );
  }

  Widget _badgeCard() {
    final owned = _badges.length;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.military_tech, size: 18, color: AppColors.amber),
          const SizedBox(width: 6),
          Text('已获得 $owned / ${MockData.badges.length} 枚',
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const Spacer(),
          const Text('点击可佩戴 / 查看',
              style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [for (final b in MockData.badges) _badgeItem(b)],
        ),
      ]),
    );
  }

  Widget _badgeItem(UserBadge b) {
    final isOwned = _badges.contains(b.id);
    final isActive = _activeBadge == b.id;
    final color = Color(b.colorValue);
    return GestureDetector(
      onTap: () => _badgeDetail(b),
      child: Column(children: [
        Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isOwned ? color.withValues(alpha: 0.14) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? color
                    : (isOwned ? color.withValues(alpha: 0.35) : Colors.transparent),
                width: isActive ? 2.2 : 1.2,
              ),
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: isOwned ? 1 : 0.32,
              child: Text(b.emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          if (isActive)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('佩戴',
                    style: TextStyle(fontSize: 8.5, color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
        const SizedBox(height: 6),
        Text(b.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: isOwned ? FontWeight.w600 : FontWeight.w500,
                color: isOwned ? AppColors.ink : AppColors.sub)),
      ]),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12.5, color: AppColors.sub, fontWeight: FontWeight.w600)),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {int maxLines = 1, bool numeric = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.sub),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : AppColors.softCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.forest : AppColors.border),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.sub)),
      ),
    );
  }
}
