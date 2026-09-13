import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 三级页：成长日历（首日 → 6 个月里程碑）
class GrowthCalendarScreen extends StatelessWidget {
  final Plant plant;
  const GrowthCalendarScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageHeader('成长日历'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SoftCard(
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(plant.image, width: 64, height: 48, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('「${plant.defaultNickname}（${plant.species}）」\n已陪伴你 ${plant.careDays} 天',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.5)),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ...MockData.growthMilestones.asMap().entries.map((e) => _milestone(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _milestone(int index, GrowthMilestone m) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 时间轴
          Column(children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: index <= 2 ? AppColors.emerald : AppColors.border,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: AppColors.border, blurRadius: 4)],
              ),
            ),
            Expanded(
              child: Container(width: 2, color: index < 2 ? AppColors.emerald : AppColors.border),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SoftCard(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Opacity(
                    opacity: index <= 1 ? 0.65 : 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(plant.image,
                          width: 72, height: 54, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(m.label,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.softCard,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(m.status,
                              style: const TextStyle(fontSize: 10.5, color: AppColors.emerald, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(m.note, style: const TextStyle(fontSize: 12, color: AppColors.sub)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
