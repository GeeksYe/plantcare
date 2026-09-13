import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'plant_detail_screen.dart';
import 'profile_edit_screen.dart';

/// 一级页：养护首页（对齐设计稿：问候+统计条+今日养护+我的花园 2×2 网格）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final store = LocalStore.instance;

  @override
  Widget build(BuildContext context) {
    final plants = MockData.plants;
    final needWater = plants.where((p) => p.needsWater).length;
    final needSun = plants.where((p) => p.light < 60).length;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.forest,
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
            _header(plants.length),
            const SizedBox(height: 14),
            _statsBar(needWater, needSun, plants.length),
            const SizedBox(height: 18),
            const SectionTitle('今日养护'),
            const SizedBox(height: 10),
            ...MockData.todayTasks.map(_careCard),
            const SizedBox(height: 18),
            const SectionTitle('我的花园'),
            const SizedBox(height: 10),
            _gardenGrid(plants),
          ],
        ),
      ),
    );
  }

  Widget _header(int plantCount) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('下午好，${store.userName}',
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text('$plantCount株绿植已接入智能花盆 · 实时守护中',
              style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
        ]),
      ),
      const SizedBox(width: 12),
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
        child: UserAvatar(
          imagePath: store.userAvatarPath,
          emoji: store.userAvatarEmoji,
          size: 46,
        ),
      ),
    ]);
  }

  Widget _statsBar(int needWater, int needSun, int total) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        _stat('$needWater', '待浇水'),
        _stat('$needSun', '需日照'),
        _stat('$total', '我的植物'),
      ]),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Column(children: [
          Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.forest)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
        ]),
      ),
    );
  }

  static const _actionWord = {'💧': '浇水', '🌱': '施肥', '☀️': '见光'};

  Widget _careCard(CareTask t) {
    final done = store.taskDone(t.id);
    final plant = MockData.plants.firstWhere((p) => p.id == t.plantId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(plant.image, width: 52, height: 52, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${plant.species} · ${_capitalLatin(plant.speciesLatin)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 3),
              Text(t.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5,
                      color: AppColors.emerald, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await store.setTaskDone(t.id, !done);
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: done ? AppColors.softCard : AppColors.forest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Text(done ? '✓' : t.icon, style: const TextStyle(fontSize: 11.5)),
                const SizedBox(width: 4),
                Text(done ? '已完成' : (_actionWord[t.icon] ?? '去完成'),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: done ? AppColors.emerald : Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  String _capitalLatin(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _gardenGrid(List<Plant> plants) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
      children: plants.map(_gardenCard).toList(),
    );
  }

  Widget _gardenCard(Plant p) {
    final nickname = store.nicknameOf(p.id, p.defaultNickname);
    final ok = !p.needsWater;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: p)));
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(p.image, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$nickname（${p.species}）',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 7, height: 7,
                    decoration: BoxDecoration(
                        color: ok ? AppColors.emerald : AppColors.amber,
                        shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(ok ? '健康' : '需浇水',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: ok ? AppColors.emerald : AppColors.amber)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
