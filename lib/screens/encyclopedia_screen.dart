import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 二级页：植物百科（搜索 + 分类 + 条目 + 热门问答）
class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  int _category = 0;
  final categories = const ['全部', '观叶', '多肉', '开花', '净化'];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final entries = MockData.wikiEntries
        .where((e) => _category == 0 || e.tag == categories[_category])
        .where((e) => e.name.contains(_query) || _query.isEmpty)
        .toList();
    return Scaffold(
      appBar: const PageHeader('植物百科'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              hintText: '搜索植物名称、学名…',
              prefixIcon: const Icon(Icons.search, color: AppColors.sub),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (i) {
                final sel = i == _category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _category = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.forest : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.forest : AppColors.border),
                      ),
                      child: Text(categories[i],
                          style: TextStyle(
                              fontSize: 12.5,
                              color: sel ? Colors.white : AppColors.sub,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          ...entries.map(_entry),
          const SizedBox(height: 8),
          SectionTitle('热门问答'),
          ...MockData.wikiQA.map(_qa),
        ],
      ),
    );
  }

  Widget _entry(e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(e.image, width: 64, height: 64, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(e.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              Text(e.latin,
                  style: const TextStyle(fontSize: 11, color: AppColors.sub, fontStyle: FontStyle.italic)),
              const SizedBox(height: 5),
              Row(children: [
                _tag(e.tag),
                const SizedBox(width: 6),
                _tag('难度 ${e.difficulty}'),
              ]),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.sub),
        ]),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.softCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10.5, color: AppColors.emerald, fontWeight: FontWeight.w600)),
    );
  }

  Widget _qa(q) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SoftCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.help_outline, size: 17, color: AppColors.forest),
            const SizedBox(width: 8),
            Expanded(
              child: Text(q.question,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(q.answer, style: const TextStyle(fontSize: 12.5, color: AppColors.sub, height: 1.6)),
        ]),
      ),
    );
  }
}
