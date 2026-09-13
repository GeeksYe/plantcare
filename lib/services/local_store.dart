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
}
