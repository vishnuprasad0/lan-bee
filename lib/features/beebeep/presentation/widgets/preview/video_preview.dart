import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:beebeep/app/theme/app_colors.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/services/file_format.dart';

/// Video with play/pause, seek bar, and elapsed / total. No autoplay, no loop.
class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key, required this.path, required this.fallback});
  final String path;
  final Widget fallback;
  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late final VideoPlayerController _controller = VideoPlayerController.file(
    File(widget.path),
  );
  bool _ready = false;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _controller.initialize().then(
      (_) {
        if (mounted) setState(() => _ready = true);
      },
      onError: (Object error) {
        debugPrint('Video init failed: $error');
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final value = _controller.value;
    if (value.isPlaying) {
      _controller.pause();
      return;
    }
    if (value.position >= value.duration) {
      _controller.seekTo(Duration.zero);
    }
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return widget.fallback;
    final colors = AppColors.of(context);
    if (!_ready) {
      return ColoredBox(
        color: colors.previewSurface,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final theme = Theme.of(context);
    final onSurface = colors.onPreviewSurface;
    return ColoredBox(
      color: colors.previewSurface,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePlay,
              child: Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final totalMs = value.duration.inMilliseconds.toDouble();
                final positionMs = value.position.inMilliseconds
                    .clamp(0, value.duration.inMilliseconds)
                    .toDouble();
                return Row(
                  children: [
                    IconButton(
                      tooltip: value.isPlaying ? 'Pause' : 'Play',
                      color: onSurface,
                      icon: Icon(
                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      onPressed: _togglePlay,
                    ),
                    Expanded(
                      child: Slider(
                        value: totalMs <= 0 ? 0 : positionMs,
                        max: totalMs <= 0 ? 1 : totalMs,
                        onChanged: totalMs <= 0
                            ? null
                            : (v) => _controller.seekTo(
                                Duration(milliseconds: v.round()),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.lg),
                      child: Text(
                        '${formatDuration(value.position)} / '
                        '${formatDuration(value.duration)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onSurface,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
