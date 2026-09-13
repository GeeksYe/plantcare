import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme.dart';

/// 三级页：播放本机短视频
class VideoPlayScreen extends StatefulWidget {
  final String path;
  const VideoPlayScreen({super.key, required this.path});

  @override
  State<VideoPlayScreen> createState() => _VideoPlayScreenState();
}

class _VideoPlayScreenState extends State<VideoPlayScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
      await _controller.setLooping(true);
      await _controller.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('视频播放',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: Center(
        child: _failed
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('视频无法播放（文件可能已被清理）',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              )
            : !_ready
                ? const CircularProgressIndicator(color: AppColors.emerald)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
      floatingActionButton: _ready
          ? FloatingActionButton(
              backgroundColor: AppColors.forest,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}
