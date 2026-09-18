import 'dart:io';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models.dart';
import '../services/local_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 弹出评论面板（社交平台式：点评论直接唤起，不跳页面）
/// 返回 true 表示评论有变化，调用方需刷新
Future<bool?> showCommentSheet(BuildContext context, {required Post post}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _CommentSheet(post: post),
  );
}

class _CommentSheet extends StatefulWidget {
  final Post post;
  const _CommentSheet({required this.post});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _store = LocalStore.instance;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

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
    _focus.dispose();
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
    _focus.unfocus();
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
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final maxH = media.size.height - keyboard - 40;
    final sheetH = (media.size.height * 0.82).clamp(320.0, maxH);
    final list = _comments;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        height: sheetH,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(children: [
          // 顶部：拖拽条 + 标题 + 关闭
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 6),
            child: Column(children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Text('${list.length} 条评论',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: const Icon(Icons.close, size: 22, color: AppColors.sub),
                ),
              ]),
            ]),
          ),
          const Divider(height: 1),
          // 评论列表
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text('还没有评论，来说两句吧～',
                        style: TextStyle(fontSize: 13.5, color: AppColors.sub)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _commentItem(list[i]),
                  ),
          ),
          const Divider(height: 1),
          _inputBar(),
        ]),
      ),
    );
  }

  Widget _commentItem(Comment c) {
    final liked = _store.commentLiked(c.id);
    final likeCount = c.likes + (liked ? 1 : 0);
    return GestureDetector(
      onLongPress: c.mine ? () => _delete(c) : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        UserAvatar(imagePath: c.avatarPath, emoji: c.avatarEmoji, size: 32),
        const SizedBox(width: 9),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(c.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              if (c.mine) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
            const SizedBox(height: 3),
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
    );
  }

  Widget _inputBar() {
    final canSend = _ctrl.text.trim().isNotEmpty;
    return Column(mainAxisSize: MainAxisSize.min, children: [
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
                focusNode: _focus,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
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
            _focus.unfocus();
            setState(() => _panel = _panel == 'emoji' ? null : 'emoji');
          }),
          const SizedBox(width: 4),
          _roundBtn(Icons.mood, const Color(0xFF8B5CF6), _panel == 'kaomoji', () {
            _focus.unfocus();
            setState(() => _panel = _panel == 'kaomoji' ? null : 'kaomoji');
          }),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: canSend ? _send : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: canSend
                    ? AppColors.forest
                    : AppColors.forest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text('发送',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ]),
      ),
      if (_panel != null) _panelArea(),
    ]);
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
      height: 200,
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
                    selectedColor:
                        isEmoji ? AppColors.forest : const Color(0xFF8B5CF6),
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
