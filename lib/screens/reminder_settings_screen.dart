import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 二级页：提醒设置（开关缓存到本地）
class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final store = LocalStore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader('提醒设置'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionTitle('养护提醒'),
          _switchRow('💧', '浇水提醒', '土壤湿度低于阈值时提醒', 'water'),
          _switchRow('🌱', '施肥提醒', '营养不足时按月提醒', 'fertilizer'),
          _switchRow('☀️', '光照提醒', '光照异常持续 3 天提醒', 'light'),
          _switchRow('🌡️', '温度预警', '超出适宜温度区间提醒', 'temp'),
          const SizedBox(height: 12),
          SectionTitle('免打扰时段'),
          SoftCard(
            child: Row(children: [
              const Icon(Icons.bedtime_outlined, size: 20, color: AppColors.forest),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('夜间免打扰', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              ),
              GestureDetector(
                onTap: () => _pickTime(true),
                child: Text(store.quietStart,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forest)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('至', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
              ),
              GestureDetector(
                onTap: () => _pickTime(false),
                child: Text(store.quietEnd,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forest)),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SectionTitle('推送方式'),
          _pushRow('📲', 'App 内推送', store.pushApp, (v) async {
            await store.setPushApp(v);
            setState(() {});
          }),
          _pushRow('✉️', '短信提醒', store.pushSms, (v) async {
            await store.setPushSms(v);
            setState(() {});
          }),
          const SizedBox(height: 16),
          const Text('设置会实时缓存到本机，联网后将同步到云端',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ],
      ),
    );
  }

  Widget _switchRow(String emoji, String title, String subtitle, String key) {
    final value = store.reminderOn(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ]),
          ),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.forest,
            onChanged: (v) async {
              await store.setReminder(key, v);
              setState(() {});
            },
          ),
        ]),
      ),
    );
  }

  Widget _pushRow(String emoji, String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
          ),
          Switch.adaptive(value: value, activeColor: AppColors.forest, onChanged: onChanged),
        ]),
      ),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = TimeOfDay(
        hour: int.parse((isStart ? store.quietStart : store.quietEnd).split(':')[0]),
        minute: int.parse((isStart ? store.quietStart : store.quietEnd).split(':')[1]));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final s = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      await store.setQuiet(
          isStart ? '$s:$m' : store.quietStart,
          isStart ? store.quietEnd : '$s:$m');
      setState(() {});
    }
  }
}
