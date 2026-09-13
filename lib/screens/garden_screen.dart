import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'plant_detail_screen.dart';

/// 二级页：我的花园
class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  final store = LocalStore.instance;

  @override
  Widget build(BuildContext context) {
    final plants = MockData.plants;
    return Scaffold(
      appBar: const PageHeader('我的花园'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SoftCard(
            child: Row(children: [
              const Icon(Icons.park, size: 20, color: AppColors.emerald),
              const SizedBox(width: 8),
              Expanded(
                child: Text('共 ${MockData.plants.length} 位绿色伙伴 · 2 位今天需要照顾',
                    style: const TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600)),
              ),
              Text('健康度均值 89%',
                  style: const TextStyle(fontSize: 12, color: AppColors.emerald, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: plants.length,
            itemBuilder: (_, i) => _plantCard(plants[i]),
          ),
          const SizedBox(height: 14),
          SectionTitle('最近动态'),
          ...MockData.growthRecords.map(_record),
          const SizedBox(height: 14),
          PrimaryButton('＋ 添加新植物', onTap: () {}),
        ],
      ),
    );
  }

  Widget _plantCard(p) {
    final nickname = store.nicknameOf(p.id, p.defaultNickname);
    final ok = !p.needsWater;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
            MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: p)));
        setState(() {});
      },
      child: Container(
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.asset(p.image, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                    child: Text('$nickname（${p.species}）',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ),
                  StatusDot(ok: ok),
                ]),
                const SizedBox(height: 3),
                Text(p.needsWater ? '需浇水' : '状态健康',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: ok ? AppColors.emerald : AppColors.amber,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _record(r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Row(children: [
          Text(r.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text(r.plantName, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ]),
          ),
          Text(r.date, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
        ]),
      ),
    );
  }
}
