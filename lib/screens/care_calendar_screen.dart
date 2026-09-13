import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 二级页：养护日历（周历 + 任务 + 本周概览 + 明日预告）
class CareCalendarScreen extends StatefulWidget {
  const CareCalendarScreen({super.key});

  @override
  State<CareCalendarScreen> createState() => _CareCalendarScreenState();
}

class _CareCalendarScreenState extends State<CareCalendarScreen> {
  final store = LocalStore.instance;
  final week = const ['一', '二', '三', '四', '五', '六', '日'];
  final dates = const [7, 8, 9, 10, 11, 12, 13];
  int selected = 4; // 周五

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader('养护日历'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _weekStrip(),
          const SizedBox(height: 14),
          SectionTitle('今日任务'),
          ...MockData.todayTasks.map(_task),
          const SizedBox(height: 14),
          SectionTitle('本周概览'),
          _weekOverview(),
          const SizedBox(height: 14),
          SectionTitle('明日预告'),
          _tomorrow(),
        ],
      ),
    );
  }

  Widget _weekStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final sel = i == selected;
          return GestureDetector(
            onTap: () => setState(() => selected = i),
            child: Column(children: [
              Text(week[i],
                  style: TextStyle(fontSize: 11.5,
                      color: sel ? Colors.white : AppColors.sub,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                width: 32, height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.forest : AppColors.softCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${dates[i]}',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.ink)),
              ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _task(t) {
    final done = store.taskDone(t.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: () async {
          await store.setTaskDone(t.id, !done);
          setState(() {});
        },
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.softCard, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(t.icon, style: const TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink,
                      decoration: done ? TextDecoration.lineThrough : null)),
              Text(t.subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ]),
          ),
          Text(done ? '已完成' : t.time,
              style: TextStyle(fontSize: 12, color: done ? AppColors.emerald : AppColors.sub,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _weekOverview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _stat('12', '本周任务'),
        _divider(),
        _stat('92%', '完成率'),
        _divider(),
        _stat('36', '累计打卡'),
      ]),
    );
  }

  Widget _stat(String v, String l) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(children: [
        Text(v, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.forest)),
        const SizedBox(height: 2),
        Text(l, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
      ]),
    ),
  );

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.border);

  Widget _tomorrow() {
    return SoftCard(
      child: Row(children: [
        const Text('🌤️', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('2 项任务等待明天',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
            SizedBox(height: 2),
            Text('给「大提琴」浇水 ·「胖胖」检查光照',
                style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.sub),
      ]),
    );
  }
}
