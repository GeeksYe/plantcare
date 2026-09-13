import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 一级页：发现 —— 社区内容流；点分享↗底部弹出社交面板（每行 3 个）
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final store = LocalStore.instance;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(children: [
            const Text('发现',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const Spacer(),
            IconButton(
              onPressed: () => _openShare(MockData.posts.first),
              icon: const Icon(Icons.ios_share, size: 20, color: AppColors.forest),
            ),
          ]),
          ...MockData.posts.map(_postCard),
        ],
      ),
    );
  }

  Widget _postCard(Post post) {
    final liked = store.isLiked(post.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            EmojiAvatar(post.avatarEmoji, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(post.author,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(post.time, style: const TextStyle(fontSize: 11, color: AppColors.sub)),
              ]),
            ),
            IconButton(
              onPressed: () => _openShare(post),
              icon: const Icon(Icons.ios_share, size: 18, color: AppColors.sub),
            ),
          ]),
          const SizedBox(height: 8),
          Text(post.text,
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.55)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(post.image, width: double.infinity, height: 140, fit: BoxFit.cover),
          ),
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
            const SizedBox(width: 22),
            _action(icon: Icons.chat_bubble_outline, color: AppColors.sub, label: '${post.comments}', onTap: () {}),
            const Spacer(),
            _action(icon: Icons.ios_share, color: AppColors.sub, label: '分享',
                onTap: () => _openShare(post)),
          ]),
        ]),
      ),
    );
  }

  Widget _action({required IconData icon, required Color color, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12.5, color: color)),
      ]),
    );
  }

  /// 底部弹出社交媒体面板：每行 3 个渠道
  void _openShare(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final channels = MockData.shareChannels.entries.toList();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const SizedBox(width: 40),
                const Expanded(
                  child: Text('分享到', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20, color: AppColors.sub),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              // 每行 3 个
              for (var row = 0; row < (channels.length / 3).ceil(); row++)
                Row(
                  children: [
                    for (var col = 0; col < 3; col++)
                      Expanded(
                        child: (row * 3 + col) < channels.length
                            ? _channel(channels[row * 3 + col])
                            : const SizedBox(),
                      ),
                  ],
                ),
              const Divider(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _textAction(Icons.link, '复制链接', () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('链接已复制到剪贴板'), backgroundColor: AppColors.forest));
                }),
                const SizedBox(width: 32),
                _textAction(Icons.system_update_alt, '系统分享', () => Navigator.pop(context)),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Widget _channel(MapEntry<String, String> channel) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('已唤起「${channel.key}」分享（演示）'),
          backgroundColor: AppColors.forest,
        ));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.softCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(channel.value, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(channel.key,
              style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
      ),
    );
  }

  Widget _textAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.forest),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.forest, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
