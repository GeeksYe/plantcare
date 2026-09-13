import 'package:flutter/material.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'rename_screen.dart';
import 'growth_calendar_screen.dart';

/// 二级页：植物详情（对齐设计稿：横幅图 + 传感器 4 块 + 营养状态 + 浇水日程 + 一键浇水）
class PlantDetailScreen extends StatefulWidget {
  final Plant plant;
  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final store = LocalStore.instance;
  bool _watering = false;
  bool _remind = false;
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.plant;
    final nickname = store.nicknameOf(p.id, p.defaultNickname);
    final waterLeft = p.needsWater ? 0 : p.waterInDays + store.extraWaterDays(p.id);

    return Scaffold(
      appBar: PageHeader('植物详情', action: GestureDetector(
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
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
                p.id == 'p1' ? 'assets/images/monstera_hero.png' : p.image,
                height: 130,
                width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Text(nickname,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => RenameScreen(plant: p)));
                setState(() {});
              },
              child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.sub),
            ),
            const Spacer(),
            Container(width: 7, height: 7,
                decoration: const BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            const Text('健康',
                style: TextStyle(fontSize: 12, color: AppColors.emerald, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 2),
          Text('${p.species} · ${p.speciesLatin}',
              style: const TextStyle(fontSize: 12.5, color: AppColors.sub, fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          _connectBar(),
          const SizedBox(height: 12),
          Row(children: [
            _sensorBlock(Icons.wb_sunny, AppColors.amber, '${p.light}%', '光照'),
            const SizedBox(width: 8),
            _sensorBlock(Icons.water_drop, AppColors.emerald, '${p.waterInDays}天', '浇水周期'),
            const SizedBox(width: 8),
            _sensorBlock(Icons.water_drop_outlined, AppColors.emerald, '${p.humidity}%', '湿度 · 适宜'),
            const SizedBox(width: 8),
            _sensorBlock(Icons.device_thermostat, const Color(0xFFB45309), '${p.temperature}°', '温度 · 适宜'),
          ]),
          if (p.warning != null) ...[
            const SizedBox(height: 12),
            _warning(p.warning!),
          ],
          const SizedBox(height: 12),
          _nutritionCard(p),
          const SizedBox(height: 16),
          const SectionTitle('浇水日程'),
          const SizedBox(height: 10),
          _waterScheduleCard(waterLeft),
          const SizedBox(height: 16),
          _waterActionRow(),
          const SizedBox(height: 16),
          _aiRow(),
          const SizedBox(height: 12),
          _growthEntry(),
        ],
      ),
    );
  }

  Widget _connectBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(width: 6, height: 6,
            decoration: const BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        const Text('智能花盆已连接 · 数据实时同步',
            style: TextStyle(fontSize: 11.5, color: AppColors.emerald, fontWeight: FontWeight.w600)),
        const Spacer(),
        const Icon(Icons.wifi, size: 14, color: AppColors.emerald),
      ]),
    );
  }

  Widget _sensorBlock(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 1),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.sub)),
        ]),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)))),
      ]),
    );
  }

  Widget _nutritionCard(Plant p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.spa, size: 17, color: AppColors.emerald),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('营养状态',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(p.needFertilizer ? '氮磷钾偏低 · 建议 2 周施肥一次' : '营养均衡 · 近期无需施肥',
                style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: p.needFertilizer ? AppColors.amber : const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(p.needFertilizer ? '建议施肥' : '营养充足',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: p.needFertilizer ? Colors.white : AppColors.emerald)),
        ),
      ]),
    );
  }

  Widget _waterScheduleCard(int waterLeft) {
    final date = DateTime.now().add(Duration(days: waterLeft));
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dateText = waterLeft <= 0
        ? '已到浇水日，建议立即浇水'
        : '${date.month}月${date.day}日 ${weekdays[date.weekday - 1]} · 还有 $waterLeft 天';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(color: AppColors.softCard, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.calendar_month_outlined, size: 19, color: AppColors.forest),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('下次浇水',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(dateText, style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _remind = !_remind),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: _remind ? const Color(0xFFE8F6EE) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.forest),
            ),
            child: Text(_remind ? '已提醒 ✓' : '提醒我',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.forest)),
          ),
        ),
      ]),
    );
  }

  Widget _waterActionRow() {
    return Row(children: [
      Expanded(
        child: SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.forest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            label: const Text('一键浇水', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
      const SizedBox(width: 10),
      GestureDetector(
        onTap: () => setState(() => _fav = !_fav),
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Icon(_fav ? Icons.favorite : Icons.favorite_border,
              size: 20, color: _fav ? AppColors.danger : AppColors.sub),
        ),
      ),
    ]);
  }

  Widget _aiRow() {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('到「识别」Tab 拍下叶片，AI 帮你诊断 🩺'), backgroundColor: AppColors.forest)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.softCard, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.healing_outlined, size: 18, color: AppColors.forest),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('绿植看病',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              SizedBox(height: 2),
              Text('叶子发黄、烂根？AI帮你诊断',
                  style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.sub),
        ]),
      ),
    );
  }

  Widget _growthEntry() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => GrowthCalendarScreen(plant: widget.plant))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FAF3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.forest, width: 1.1),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBBE3C8)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.calendar_month_outlined, size: 19, color: AppColors.forest),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('成长日历',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.forest)),
              SizedBox(height: 2),
              Text('首日到 6 个月 · 5 次成长记录',
                  style: TextStyle(fontSize: 11, color: AppColors.emerald)),
            ]),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.forest),
        ]),
      ),
    );
  }
}
