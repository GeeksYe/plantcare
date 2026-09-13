import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../services/local_store.dart';
import '../services/media_store.dart';
import '../theme.dart';

/// 二级页：发布动态（文字 + 表情 + 多图 + 短视频），全部保存在本机
class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _store = LocalStore.instance;
  final _picker = ImagePicker();
  final _textCtrl = TextEditingController();

  final List<String> _images = [];
  String? _video;
  int _videoSec = 0;
  final List<String> _tags = [];
  bool _saving = false;

  static const _maxImages = 9;

  static const _emojiGroups = {
    '常用': ['😀', '😄', '😊', '🥰', '😍', '🤔', '😴', '🥳', '😭', '😅', '👍', '🙏', '✨', '💚', '🌿', '🎉'],
    '植物': ['🌱', '🌿', '☘️', '🍀', '🌵', '🌴', '🌳', '🌲', '🌸', '🌺', '🌻', '🌹', '🌷', '🌼', '🍃', '🍂'],
    '表情包': ['🤣', '😂', '😱', '🤯', '🥲', '😎', '🤗', '😇', '🤠', '👀', '💪', '🔥', '⭐️', '💯', '🫶', '😤'],
    '养护': ['💧', '☀️', '🌙', '🌡️', '🪴', '🧴', '✂️', '🪣', '🌾', '🐛', '🍄', '🪴', '🧪', '🌈', '🍂', '🌬️'],
  };

  static const _topicOptions = [
    '#开背日记', '#新手养花', '#多肉控', '#浇水心得', '#光照充足',
    '#换盆记', '#病虫害防治', '#绿植照相馆', '#阳台花园', '#成长记录',
  ];

  bool get _hasContent =>
      _textCtrl.text.trim().isNotEmpty || _images.isNotEmpty || _video != null;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  // ---------------- 媒体选择 ----------------
  Future<void> _pickImages() async {
    final files =
        await _picker.pickMultiImage(imageQuality: 85, maxWidth: 1280);
    if (files.isEmpty) return;
    for (final f in files) {
      if (_images.length >= _maxImages) break;
      _images.add(await MediaStore.save(f.path, kind: 'image'));
    }
    if (mounted) setState(() {});
  }

  Future<void> _takePhoto() async {
    final f = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 85, maxWidth: 1280);
    if (f == null) return;
    if (_images.length >= _maxImages) return;
    final path = await MediaStore.save(f.path, kind: 'image');
    if (mounted) setState(() => _images.add(path));
  }

  Future<void> _pickVideo({required ImageSource source}) async {
    final f = await _picker.pickVideo(
        source: source, maxDuration: const Duration(seconds: 60));
    if (f == null) return;
    final path = await MediaStore.save(f.path, kind: 'video');
    var sec = 0;
    try {
      final c = VideoPlayerController.file(File(path));
      await c.initialize();
      sec = c.value.duration.inSeconds;
      await c.dispose();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _video = path;
      _videoSec = sec;
    });
  }

  void _removeImage(int i) => setState(() => _images.removeAt(i));

  void _removeVideo() => setState(() {
        _video = null;
        _videoSec = 0;
      });

  // ---------------- 表情 / 话题 ----------------
  void _insertEmoji(String e) {
    final text = _textCtrl.text;
    final sel = _textCtrl.selection;
    final start = (sel.start < 0 || sel.start > text.length) ? text.length : sel.start;
    final end = (sel.end < 0 || sel.end > text.length) ? text.length : sel.end;
    final next = text.replaceRange(start, end, e);
    _textCtrl.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + e.length),
    );
    setState(() {});
  }

  void _emojiSheet() {
    var group = _emojiGroups.keys.first;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        return Container(
          height: 330,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Column(children: [
            Row(children: [
              const Text('插入表情',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, size: 20, color: AppColors.sub),
              ),
            ]),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final g in _emojiGroups.keys)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: group == g,
                        selectedColor: AppColors.forest,
                        labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: group == g ? Colors.white : AppColors.sub),
                        onSelected: (_) => setSheet(() => group = g),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: GridView.count(
                crossAxisCount: 8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  for (final e in _emojiGroups[group]!)
                    GestureDetector(
                      onTap: () => _insertEmoji(e),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.softCard,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        );
      }),
    );
  }

  void _topicSheet() {
    final selected = List<String>.from(_tags);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('选择话题标签',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink)),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final t in _topicOptions)
                GestureDetector(
                  onTap: () => setSheet(() {
                    if (selected.contains(t)) {
                      selected.remove(t);
                    } else if (selected.length < 3) {
                      selected.add(t);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected.contains(t)
                          ? AppColors.emerald
                          : AppColors.softCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: selected.contains(t)
                              ? AppColors.emerald
                              : AppColors.border),
                    ),
                    child: Text(t,
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected.contains(t)
                                ? Colors.white
                                : AppColors.sub)),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  setState(() {
                    _tags
                      ..clear()
                      ..addAll(selected);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('确定',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ]),
        );
      }),
    );
  }

  // ---------------- 发布 ----------------
  Future<void> _publish() async {
    if (!_hasContent || _saving) return;
    setState(() => _saving = true);
    await _store.addMyPost({
      'id': 'my_${DateTime.now().millisecondsSinceEpoch}',
      'text': _textCtrl.text.trim(),
      'images': _images,
      'video': _video ?? '',
      'videoSec': _videoSec,
      'tags': _tags,
      'time': '刚刚',
      'likes': 0,
      'comments': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发布成功，已保存到本机')));
    Navigator.pop(context, true);
  }

  // ---------------- 页面 ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消',
              style: TextStyle(fontSize: 14.5, color: AppColors.sub)),
        ),
        title: const Text('发布动态',
            style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _hasContent ? _publish : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: _hasContent
                      ? AppColors.forest
                      : AppColors.forest.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(_saving ? '发布中…' : '发布',
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            children: [
              _editor(),
              const SizedBox(height: 12),
              _mediaGrid(),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  for (final t in _tags)
                    Chip(
                      label: Text(t,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w600)),
                      backgroundColor: AppColors.emerald.withValues(alpha: 0.1),
                      deleteIconColor: AppColors.sub,
                      onDeleted: () => setState(() => _tags.remove(t)),
                      side: BorderSide.none,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ]),
              ],
              const SizedBox(height: 10),
              const Center(
                child: Text('文字 · 表情 · 图片 · 短视频，全部保存在本机',
                    style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
              ),
            ],
          ),
        ),
        _toolBar(),
      ]),
    );
  }

  Widget _editor() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.edit_note, size: 18, color: AppColors.emerald),
          const SizedBox(width: 6),
          Text('说说你的绿植日常',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink.withValues(alpha: 0.75))),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: _textCtrl,
          maxLines: 6,
          minLines: 6,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.6),
          decoration: const InputDecoration(
            hintText: '分享养护心得、开背瞬间或踩过的坑…\n可以插入表情 😊 和话题标签 #',
            hintStyle: TextStyle(fontSize: 13.5, color: AppColors.sub, height: 1.6),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ]),
    );
  }

  Widget _mediaGrid() {
    final items = <Widget>[
      for (var i = 0; i < _images.length; i++)
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(_images[i]),
                width: double.infinity, height: double.infinity,
                fit: BoxFit.cover),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: () => _removeImage(i),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ]),
      if (_video != null)
        Stack(children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F2A1D),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.play_circle_fill,
                size: 40, color: Colors.white),
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                  '${_videoSec ~/ 60}:${(_videoSec % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: GestureDetector(
              onTap: _removeVideo,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ]),
    ];

    final canAdd = _images.length < _maxImages && _video == null;
    if (canAdd) {
      items.add(GestureDetector(
        onTap: _pickImages,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.softCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add_photo_alternate_outlined,
                size: 26, color: AppColors.emerald),
            const SizedBox(height: 4),
            Text('${_images.length}/$_maxImages',
                style: const TextStyle(fontSize: 11, color: AppColors.sub)),
          ]),
        ),
      ));
    }

    if (items.isEmpty) return const SizedBox();

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: items,
    );
  }

  Widget _toolBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(children: [
          _tool(Icons.emoji_emotions_outlined, '表情', AppColors.amber, _emojiSheet),
          _tool(Icons.photo_library_outlined, '图片', AppColors.emerald, _pickImages),
          _tool(Icons.photo_camera_outlined, '拍照', AppColors.forest, _takePhoto),
          _tool(Icons.videocam_outlined, '视频', const Color(0xFF7C3AED),
              () => _videoSheet()),
          _tool(Icons.tag, '话题', const Color(0xFF0EA5E9), _topicSheet),
        ]),
      ),
    );
  }

  void _videoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('添加短视频',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _bigAction(Icons.video_library_outlined, '从相册选择',
                  AppColors.emerald, () {
                Navigator.pop(context);
                _pickVideo(source: ImageSource.gallery);
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _bigAction(Icons.videocam, '拍摄新视频', AppColors.forest, () {
                Navigator.pop(context);
                _pickVideo(source: ImageSource.camera);
              }),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('单个视频最长 60 秒，保存在本机',
              style: TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
      ),
    );
  }

  Widget _bigAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _tool(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 11.5, color: AppColors.sub)),
        ]),
      ),
    );
  }
}
