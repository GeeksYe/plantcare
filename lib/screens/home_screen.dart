import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'plant_detail_screen.dart';

/// 一级页：养护首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final store = LocalStore.instance;

  @override
  Widget build(BuildContext context) {
    final needCare = MockData.plants.where((p) => p.needsWater || p.needFertilizer).length;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _header(needCare),
            const SizedBox(height: 14),
            _sensorOverview(),
            const SizedBox(height: 16),
            SectionTitle('我的绿植', action: '全部 ›',
                onAction: () => setState(() {})),
            SizedBox(
              height: 218,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.plants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _plantCard(MockData.plants[i]),
              ),
            ),
            const SizedBox(height: 14),
            SectionTitle('今日任务'),
            ...MockData.todayTasks.map(_taskCard),
          ],
        ),
      ),
    );
  }

  Widget _header(int needCare) {
    return Row(
      children: [
        const EmojiAvatar('🌿', size: 44),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('早上好，园丁 🌞',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text('有 $needCare 位绿色伙伴今天需要照顾',
                style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
          ]),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, color: AppColors.ink),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sensorOverview() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF166534), Color(0xFF15803D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('智能花盆 · 已连接',
                style: TextStyle(color: Colors.white70, fontSize: 11.5)),
            SizedBox(height: 4),
            Text('花园环境一切正常',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
          const Spacer(),
          _envChip('💧 65%', Icons.water_drop),
          const SizedBox(width: 8),
          _envChip('☀️ 72%', Icons.wb_sunny),
        ],
      ),
    );
  }

  Widget _envChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _plantCard(Plant p) {
    final nickname = store.nicknameOf(p.id, p.defaultNickname);
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: p)));
        setState(() {});
      },
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(p.image, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text('$nickname（${p.species}）',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              StatusDot(ok: !p.needsWater),
            ]),
            const SizedBox(height: 2),
            Text('养护 ${p.careDays} 天 · ${p.warning ?? '状态健康'}',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.sub)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: SensorChip(icon: Icons.water_drop_outlined, label: '湿度', value: '${p.humidity}%')),
              const SizedBox(width: 6),
              Expanded(child: SensorChip(icon: Icons.device_thermostat, label: '温度', value: '${p.temperature}°')),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _taskCard(CareTask t) {
    final done = store.taskDone(t.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        onTap: () async {
          await store.setTaskDone(t.id, !done);
          setState(() {});
        },
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(color: AppColors.softCard, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(t.icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: done ? AppColors.sub : AppColors.ink,
                        decoration: done ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 2),
                Text(t.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: done ? AppColors.softCard : (t.urgent ? const Color(0xFFFFF7ED) : AppColors.softCard),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(done ? '已完成 ✓' : t.time,
                  style: TextStyle(
                      fontSize: 12,
                      color: done ? AppColors.emerald : (t.urgent ? AppColors.amber : AppColors.sub),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
