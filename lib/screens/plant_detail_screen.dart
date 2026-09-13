import 'package:flutter/material.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'rename_screen.dart';
import 'growth_calendar_screen.dart';

/// 二级页：植物详情（传感器 + 营养状态 + 成长日历入口）
class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final store = LocalStore.instance;
  bool _watering = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.plant;
    final nickname = store.nicknameOf(p.id, p.defaultNickname);
    final waterLeft = p.needsWater ? 0 : p.waterInDays + store.extraWaterDays(p.id);

    return Scaffold(
      appBar: PageHeader(nickname, action: GestureDetector(
        onTap: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => RenameScreen(plant: p)));
          setState(() {});
        },
        child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.sub),
      )),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
                p.id == 'p1' ? 'assets/images/monstera_hero.png' : p.image,
                height: p.id == 'p1' ? 128 : 150,
                width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Text('$nickname（${p.species}）',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const Spacer(),
            const StatusDot(ok: true),
            const SizedBox(width: 5),
            Text('健康度 ${p.health}%',
                style: const TextStyle(fontSize: 12.5, color: AppColors.emerald, fontWeight: FontWeight.w600)),
          ]),
          Text(p.speciesLatin,
              style: const TextStyle(fontSize: 12, color: AppColors.sub, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          Row(children: [
            SensorChip(icon: Icons.water_drop_outlined, label: '湿度', value: '${p.humidity}%'),
            const SizedBox(width: 6),
            SensorChip(icon: Icons.device_thermostat, label: '温度', value: '${p.temperature}°C'),
            const SizedBox(width: 6),
            SensorChip(icon: Icons.wb_sunny_outlined, label: '光照', value: '${p.light}%'),
          ]),
          if (p.warning != null) ...[
            const SizedBox(height: 12),
            _warning(p.warning!),
          ],
          const SizedBox(height: 16),
          _nutritionCard(p),
          const SizedBox(height: 16),
          _waterCard(waterLeft),
          const SizedBox(height: 16),
          _growthEntry(nickname),
        ],
      ),
    );
  }

  Widget _warning(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.amber),
        const SizedBox(width: 8),
        Expanded(child: Text('智能花盆提醒：$text',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF92400E)))),
      ]),
    );
  }

  Widget _nutritionCard(Plant p) {
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.spa, size: 18, color: AppColors.emerald),
          SizedBox(width: 6),
          Text('营养状态', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
          Spacer(),
          Text(p.needFertilizer ? '建议施肥' : '营养充足',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                  color: p.needFertilizer ? AppColors.amber : AppColors.emerald)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: p.needFertilizer ? 0.32 : 0.78,
            minHeight: 8,
            backgroundColor: AppColors.softCard,
            color: p.needFertilizer ? AppColors.amber : AppColors.emerald,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p.needFertilizer
              ? '土壤氮磷钾偏低，建议本月内施一次稀释液肥'
              : '近期无需施肥，保持现有养护节奏即可',
          style: const TextStyle(fontSize: 12, color: AppColors.sub),
        ),
      ]),
    );
  }

  Widget _waterCard(int waterLeft) {
    return SoftCard(
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('智能浇水',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(waterLeft <= 0 ? '已缺水，建议立即浇水' : '约 $waterLeft 天后需要浇水',
                style: const TextStyle(fontSize: 12, color: AppColors.sub)),
          ]),
        ),
        SizedBox(
          height: 40,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _watering
                ? null
                : () async {
                    setState(() => _watering = true);
                    await Future.delayed(const Duration(milliseconds: 900));
                    await store.markWatered(widget.plant.id);
                    setState(() => _watering = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('已为它浇水 220ml，记录已缓存到本地 💧'),
                        backgroundColor: AppColors.forest,
                      ));
                    }
                  },
            icon: _watering
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.water_drop, size: 18),
            label: const Text('一键浇水', style: TextStyle(fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  Widget _growthEntry(String nickname) {
    return SoftCard(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => GrowthCalendarScreen(plant: widget.plant))),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: const BoxDecoration(color: AppColors.softCard, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Text('📸', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('成长日历', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            Text('查看 $nickname 的 6 个月成长影像',
                style: const TextStyle(fontSize: 12, color: AppColors.sub)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.sub),
      ]),
    );
  }
}
