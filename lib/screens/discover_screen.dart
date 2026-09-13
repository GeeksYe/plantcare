import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 一级页：发现（对齐设计稿：发布+搜索+分类chips+内容流+碎碎念；点分享弹社交面板每行3个）
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final store = LocalStore.instance;
  final _followed = <String>{};
  int _category = 0;
  static const _categories = ['推荐', '多肉', '观叶', '鲜花', '新手'];

  // 设计稿分享渠道：圆形彩色图标，每行 3 个
  static const _channels = [
    ('App内好友', '友', Color(0xFF15803D)),
    ('微信', '微', Color(0xFF07C160)),
    ('朋友圈', '朋', Color(0xFF43A047)),
    ('Facebook', 'F', Color(0xFF1877F2)),
    ('微博', '博', Color(0xFFE6162D)),
    ('复制链接', '链', Color(0xFF6B7280)),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          _header(),
          const SizedBox(height: 12),
          _searchBar(),
          const SizedBox(height: 12),
          _categoryChips(),
          const SizedBox(height: 6),
          ..._buildFeed(),
        ],
      ),
    );
  }

  List<Widget> _buildFeed() {
    return [for (final post in MockData.posts) post.isMurmur ? _murmurCard(post) : _postCard(post)];
  }

  Widget _header() {
    return Row(children: [
      const Text('发现',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.ink)),
      const Spacer(),
      GestureDetector(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发布功能演示：写下你的养植心得吧 🌿'),
                backgroundColor: AppColors.forest)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Text('＋ 发布',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(children: [
        Icon(Icons.search, size: 18, color: AppColors.sub),
        SizedBox(width: 6),
        Text('搜索植物、话题或花友', style: TextStyle(fontSize: 12.5, color: AppColors.sub)),
      ]),
    );
  }

  Widget _categoryChips() {
    return Row(children: [
      for (var i = 0; i < _categories.length; i++)
        GestureDetector(
          onTap: () => setState(() => _category = i),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            decoration: BoxDecoration(
              color: _category == i ? AppColors.forest : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: _category == i ? AppColors.forest : AppColors.border),
            ),
            child: Text(_categories[i],
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _category == i ? Colors.white : AppColors.sub)),
          ),
        ),
    ]);
  }

  Widget _postCard(Post post) {
    final liked = store.isLiked(post.id);
    final followed = _followed.contains(post.id);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            EmojiAvatar(post.avatarEmoji, size: 36),
            const SizedBox(width: 9),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post.author,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('· ${post.time}', style: const TextStyle(fontSize: 10.5, color: AppColors.sub)),
              ]),
            ),
            GestureDetector(
              onTap: () => setState(() =>
                  followed ? _followed.remove(post.id) : _followed.add(post.id)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: followed ? const Color(0xFFF3F7F4) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: followed ? AppColors.border : AppColors.forest),
                ),
                child: Text(followed ? '已关注' : '关注',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600,
                        color: followed ? AppColors.sub : AppColors.forest)),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(post.image, width: double.infinity, height: 150, fit: BoxFit.cover),
          ),
          const SizedBox(height: 10),
          Text(post.text,
              style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.55)),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(spacing: 10, children: [
              for (final t in post.tags)
                Text(t, style: const TextStyle(fontSize: 12, color: AppColors.emerald, fontWeight: FontWeight.w600)),
            ]),
          ],
          const SizedBox(height: 10),
          Row(children: [
            _action(
              icon: liked ? Icons.favorite : Icons.favorite_border,
              color: liked ? AppColors.danger : AppColors.sub,
              label: '${post.likes + (liked ? 1 : 0)}',
              onTap: () async {
                await store.toggleLike(post.id);
                setState(() {});
              },
            ),
            const SizedBox(width: 20),
            _action(icon: Icons.mode_comment_outlined, color: AppColors.sub, label: '${post.comments}', onTap: () {}),
            const Spacer(),
            GestureDetector(
              onTap: () => _openShare(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F4),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(children: [
                  Text('分享', style: TextStyle(fontSize: 11.5, color: AppColors.ink, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.ios_share, size: 12, color: AppColors.ink),
                ]),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _murmurCard(Post post) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('今日碎碎念',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(post.text,
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.55)),
          const SizedBox(height: 6),
          Wrap(spacing: 10, children: [
            for (final t in post.tags)
              Text(t, style: const TextStyle(fontSize: 12, color: AppColors.emerald, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }

  Widget _action({required IconData icon, required Color color, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ]),
    );
  }

  /// 底部弹出社交媒体面板（对齐设计稿：标题居中 + 每行 3 个彩色圆 + 底部取消条）
  void _openShare() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('分享给好友 · 一起养好绿植',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 18),
              for (var row = 0; row < (_channels.length / 3).ceil(); row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    for (var col = 0; col < 3; col++)
                      Expanded(
                        child: (row * 3 + col) < _channels.length
                            ? _channel(_channels[row * 3 + col])
                            : const SizedBox(),
                      ),
                  ]),
                ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: const Text('取消',
                      style: TextStyle(fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w500)),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _channel((String, String, Color) channel) {
    final (name, glyph, color) = channel;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(name == '复制链接' ? '链接已复制到剪贴板' : '已唤起「$name」分享（演示）'),
          backgroundColor: AppColors.forest,
        ));
      },
      child: Column(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(glyph,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
      ]),
    );
  }
}
