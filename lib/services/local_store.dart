import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 本地缓存层：暂不接服务器，所有用户操作数据先落本地
/// - 植物自定义昵称
/// - 提醒设置（开关/免打扰/推送方式）
/// - 浇水记录（打卡后推迟下次浇水天数）
/// - 发现页点赞
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---------- 昵称 ----------
  String nicknameOf(String plantId, String fallback) =>
      _prefs.getString('nickname_$plantId') ?? fallback;

  Future<void> setNickname(String plantId, String nickname) =>
      _prefs.setString('nickname_$plantId', nickname);

  // ---------- 提醒设置 ----------
  bool reminderOn(String key) => _prefs.getBool('reminder_$key') ?? true;
  Future<void> setReminder(String key, bool value) =>
      _prefs.setBool('reminder_$key', value);

  String get quietStart => _prefs.getString('quiet_start') ?? '22:00';
  String get quietEnd => _prefs.getString('quiet_end') ?? '07:00';
  Future<void> setQuiet(String start, String end) async {
    await _prefs.setString('quiet_start', start);
    await _prefs.setString('quiet_end', end);
  }

  bool get pushApp => _prefs.getBool('push_app') ?? true;
  bool get pushSms => _prefs.getBool('push_sms') ?? false;
  Future<void> setPushApp(bool v) => _prefs.setBool('push_app', v);
  Future<void> setPushSms(bool v) => _prefs.setBool('push_sms', v);

  // ---------- 浇水记录：打卡后 waterInDays 重置 ----------
  int extraWaterDays(String plantId) => _prefs.getInt('water_$plantId') ?? 0;
  Future<void> markWatered(String plantId, {int cycle = 7}) =>
      _prefs.setInt('water_$plantId', cycle);

  // ---------- 点赞 ----------
  bool isLiked(String postId) => _prefs.getBool('like_$postId') ?? false;
  Future<void> toggleLike(String postId) async {
    await _prefs.setBool('like_$postId', !isLiked(postId));
  }

  // ---------- 已完成任务 ----------
  bool taskDone(String taskId) => _prefs.getBool('done_$taskId') ?? false;
  Future<void> setTaskDone(String taskId, bool done) =>
      _prefs.setBool('done_$taskId', done);

  // ---------- 用户资料 ----------
  String get userName => _prefs.getString('user_name') ?? '小满';
  Future<void> setUserName(String v) =>
      _prefs.setString('user_name', v.trim().isEmpty ? '小满' : v.trim());

  String get userBio =>
      _prefs.getString('user_bio') ?? '用心记录每一片叶子的成长 🌿';
  Future<void> setUserBio(String v) => _prefs.setString('user_bio', v.trim());

  String get userGender => _prefs.getString('user_gender') ?? '未设置';
  Future<void> setUserGender(String v) => _prefs.setString('user_gender', v);

  String get userCity => _prefs.getString('user_city') ?? '未设置';
  Future<void> setUserCity(String v) => _prefs.setString('user_city', v.trim());

  /// 头像：优先展示上传的本地照片路径，其次 emoji 预设头像
  String? get userAvatarPath => _prefs.getString('user_avatar');
  Future<void> setUserAvatarPath(String? v) async {
    if (v == null) {
      await _prefs.remove('user_avatar');
    } else {
      await _prefs.setString('user_avatar', v);
    }
  }

  String get userAvatarEmoji => _prefs.getString('user_avatar_emoji') ?? '🌿';
  Future<void> setUserAvatarEmoji(String v) =>
      _prefs.setString('user_avatar_emoji', v);

  /// 养护开始日（默认 128 天前）
  DateTime get careStartDate {
    final s = _prefs.getString('care_start');
    final fallback = DateTime.now().subtract(const Duration(days: 128));
    if (s == null) return fallback;
    return DateTime.tryParse(s) ?? fallback;
  }

  int get careDays {
    final d = DateTime.now().difference(careStartDate).inDays;
    return d < 0 ? 0 : d;
  }

  Future<void> setCareStartDate(DateTime d) => _prefs.setString(
      'care_start',
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');

  int get checkinDays => _prefs.getInt('checkin_days') ?? 36;
  Future<void> setCheckinDays(int v) => _prefs.setInt('checkin_days', v);

  // ---------- 我发布的动态（本机保存）----------
  List<Map<String, dynamic>> get myPosts {
    final raw = _prefs.getStringList('my_posts') ?? const [];
    final list = <Map<String, dynamic>>[];
    for (final e in raw) {
      try {
        list.add(jsonDecode(e) as Map<String, dynamic>);
      } catch (_) {}
    }
    return list;
  }

  Future<void> addMyPost(Map<String, dynamic> post) async {
    final list = _prefs.getStringList('my_posts') ?? <String>[];
    list.insert(0, jsonEncode(post));
    await _prefs.setStringList('my_posts', list);
  }

  Future<void> deleteMyPost(String id) async {
    final list = myPosts..removeWhere((p) => p['id'] == id);
    await _prefs.setStringList(
        'my_posts', list.map((e) => jsonEncode(e)).toList());
  }

  // ---------- 勋章 ----------
  List<String> get _defaultBadges => ['newbie', 'expert', 'streak'];

  List<String> get badges =>
      _prefs.getStringList('badges') ?? _defaultBadges;

  bool hasBadge(String id) => badges.contains(id);

  Future<void> unlockBadge(String id) async {
    final list = badges;
    if (list.contains(id)) return;
    list.add(id);
    await _prefs.setStringList('badges', list);
    await _prefs.setString('badge_date_$id', _today());
  }

  Future<void> lockBadge(String id) async {
    final list = badges..remove(id);
    await _prefs.setStringList('badges', list);
    await _prefs.remove('badge_date_$id');
    if (activeBadge == id) await setActiveBadge('');
  }

  String badgeDate(String id) => _prefs.getString('badge_date_$id') ?? '';

  /// 佩戴中的勋章（展示在昵称旁）
  String get activeBadge => _prefs.getString('active_badge') ?? 'expert';
  Future<void> setActiveBadge(String id) =>
      _prefs.setString('active_badge', id);

  static String _today() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
