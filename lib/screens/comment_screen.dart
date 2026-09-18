import 'dart:io';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 二级页：动态评论（支持文本 / 表情包 / 颜文字，评论保存在本机）
class CommentScreen extends StatefulWidget {
  final Post post;
  const CommentScreen({super.key, required this.post});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final _store = LocalStore.instance;
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  /// null / 'emoji' / 'kaomoji'
  String? _panel;
  String _emojiGroup = '常用';
  String _kaomojiGroup = '开心';

  static const _emojiGroups = {
    '常用': ['😀', '😄', '😊', '🥰', '😍', '🤔', '😴', '🥳', '😭', '😅', '👍', '🙏', '✨', '💚', '🌿', '🎉'],
    '植物': ['🌱', '🌿', '☘️', '🍀', '🌵', '🌴', '🌳', '🌲', '🌸', '🌺', '🌻', '🌹', '🌷', '🌼', '🍃', '🍂'],
    '表情包': ['🤣', '😂', '😱', '🤯', '🥲', '😎', '🤗', '😇', '🤠', '👀', '💪', '🔥', '⭐️', '💯', '🫶', '😤'],
    '养护': ['💧', '☀️', '🌙', '🌡️', '🪴', '🧴', '✂️', '🪣', '🌾', '🐛', '🍄', '🧪', '🌈', '🌬️', '🪣', '🌞'],
  };

  Post get post => widget.post;

  List<Comment> get _comments {
    final mine = _store.commentsOf(post.id).map((m) => Comment(
          id: '${m['id']}',
          postId: post.id,
          author: (m['author'] ?? _store.userName) as String,
          avatarEmoji: (m['avatarEmoji'] ?? _store.userAvatarEmoji) as String,
          avatarPath: m['avatarPath'] as String?,
          text: (m['text'] ?? '') as String,
          time: (m['time'] ?? '刚刚') as String,
          likes: (m['likes'] ?? 0) as int,
          mine: true,
        ));
    final preset = MockData.commentsByPost[post.id] ?? const <Comment>[];
    return <Comment>[...mine, ...preset];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _insert(String s) {
    final text = _ctrl.text;
    final sel = _ctrl.selection;
    final start =
        (sel.start < 0 || sel.start > text.length) ? text.length : sel.start;
    final end = (sel.end < 0 || sel.end > text.length) ? text.length : sel.end;
    _ctrl.value = TextEditingValue(
      text: text.replaceRange(start, end, s),
      selection: TextSelection.collapsed(offset: start + s.length),
    );
    setState(() {});
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    await _store.addComment(post.id, {
      'id': 'c_${DateTime.now().millisecondsSinceEpoch}',
      'author': _store.userName,
      'avatarEmoji': _store.userAvatarEmoji,
      'avatarPath': _store.userAvatarPath,
      'text': text,
      'time': '刚刚',
      'likes': 0,
    });
    _ctrl.clear();
    setState(() => _panel = null);
    FocusScope.of(context).unfocus();
  }

  Future<void> _delete(Comment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('删除这条评论？',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: const Text('删除后无法恢复。',
            style: TextStyle(fontSize: 13, color: AppColors.sub)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消', style: TextStyle(color: AppColors.sub))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('删除',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) {
      await _store.deleteComment(post.id, c.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _comments;
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
        title: Text('评论 ${list.length}',
            style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        centerTitle: true,
      ),
      body: Column(children: [
        _postSummary(),
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('还没有评论，来说两句吧～',
                      style: TextStyle(fontSize: 13.5, color: AppColors.sub)))
              : ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) => _commentItem(list[i]),
                ),
        ),
        _inputBar(),
          ]),
        ),
      );
  }

  Widget _postSummary() {
    final thumb = post.images.isNotEmpty
        ? post.images.first
        : (post.image.isNotEmpty ? post.image : '');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        UserAvatar(
            imagePath: post.avatarPath, emoji: post.avatarEmoji, size: 34),
        const SizedBox(width: 9),
        Expanded(
          child: Text(post.text.isEmpty ? '（图片动态）' : post.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: AppColors.sub)),
        ),
        if (thumb.isNotEmpty) ...[
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: thumb.startsWith('assets/')
                  ? Image.asset(thumb, fit: BoxFit.cover)
                  : (File(thumb).existsSync()
                      ? Image.file(File(thumb), fit: BoxFit.cover)
                      : Container(
                          color: AppColors.softCard,
                          alignment: Alignment.center,
                          child: const Icon(Icons.videocam,
                              size: 18, color: AppColors.sub),
                        )),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _commentItem(Comment c) {
    final liked = _store.commentLiked(c.id);
    final likeCount = c.likes + (liked ? 1 : 0);
    return GestureDetector(
      onLongPress: c.mine ? () => _delete(c) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.mine ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          UserAvatar(imagePath: c.avatarPath, emoji: c.avatarEmoji, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(c.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
                if (c.mine) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('我',
                        style: TextStyle(
                            fontSize: 9,
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
                const SizedBox(width: 6),
                Text(c.time,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.sub)),
              ]),
              const SizedBox(height: 4),
              Text(c.text,
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.ink, height: 1.5)),
            ]),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () async {
              await _store.toggleCommentLike(c.id);
              if (mounted) setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(children: [
                Icon(liked ? Icons.favorite : Icons.favorite_border,
                    size: 16, color: liked ? AppColors.danger : AppColors.sub),
                const SizedBox(height: 2),
                Text('$likeCount',
                    style: TextStyle(
                        fontSize: 11,
                        color: liked ? AppColors.danger : AppColors.sub)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _inputBar() {
    final canSend = _ctrl.text.trim().isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.softCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 4,
                    onTap: () => setState(() => _panel = null),
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    decoration: const InputDecoration(
                      hintText: '说点什么…支持表情和颜文字',
                      hintStyle: TextStyle(fontSize: 13, color: AppColors.sub),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _roundBtn(Icons.emoji_emotions_outlined, AppColors.amber,
                  _panel == 'emoji', () {
                FocusScope.of(context).unfocus();
                setState(() => _panel = _panel == 'emoji' ? null : 'emoji');
              }),
              const SizedBox(width: 4),
              _roundBtn(Icons.mood, const Color(0xFF8B5CF6), _panel == 'kaomoji',
                  () {
                FocusScope.of(context).unfocus();
                setState(() => _panel = _panel == 'kaomoji' ? null : 'kaomoji');
              }),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: canSend ? _send : null,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: canSend
                        ? AppColors.forest
                        : AppColors.forest.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('发送',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ]),
          ),
          if (_panel != null) _panelArea(),
        ]),
      ),
    );
  }

  Widget _roundBtn(IconData icon, Color color, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.14) : AppColors.softCard,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: active ? color : AppColors.sub),
      ),
    );
  }

  Widget _panelArea() {
    final isEmoji = _panel == 'emoji';
    final groups = isEmoji ? _emojiGroups : MockData.kaomojiGroups;
    final current = isEmoji ? _emojiGroup : _kaomojiGroup;
    final items = groups[current] ?? const <String>[];

    return Container(
      height: 236,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(children: [
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final g in groups.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(g),
                    selected: current == g,
                    selectedColor: isEmoji ? AppColors.forest : const Color(0xFF8B5CF6),
                    labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: current == g ? Colors.white : AppColors.sub),
                    onSelected: (_) => setState(() {
                      if (isEmoji) {
                        _emojiGroup = g;
                      } else {
                        _kaomojiGroup = g;
                      }
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: isEmoji
              ? GridView.count(
                  crossAxisCount: 8,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  children: [
                    for (final e in items)
                      GestureDetector(
                        onTap: () => _insert(e),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                  ],
                )
              : GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 3.4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (final k in items)
                      GestureDetector(
                        onTap: () => _insert(k),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(k,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.ink)),
                        ),
                      ),
                  ],
                ),
        ),
      ]),
    );
  }
}
