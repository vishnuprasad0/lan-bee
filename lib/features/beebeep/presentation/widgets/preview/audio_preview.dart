import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/services/file_format.dart';
import '../../bloc/voice_playback/voice_playback_cubit.dart';
import '../../bloc/voice_playback/voice_playback_state.dart';

/// Simple audio player: play/pause, seek slider, elapsed / total. Shares the
/// voice player, and pauses when the page is left.
class AudioPreview extends StatefulWidget {
  const AudioPreview({
    super.key,
    required this.messageId,
    required this.path,
    this.total,
  });

  /// Owner id for the shared player (the message id).
  final String messageId;
  final String path;

  /// Duration hint, used until the player reports the real one.
  final Duration? total;
  @override
  State<AudioPreview> createState() => _AudioPreviewState();
}

class _AudioPreviewState extends State<AudioPreview> {
  late final VoicePlaybackCubit _cubit = context.read<VoicePlaybackCubit>();
  @override
  void dispose() {
    _cubit.pauseIfPlaying(widget.messageId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return BlocBuilder<VoicePlaybackCubit, VoicePlaybackState>(
      buildWhen: (previous, current) =>
          previous.messageId == widget.messageId ||
          current.messageId == widget.messageId,
      builder: (context, state) {
        final active = state.messageId == widget.messageId;
        final playing = active && state.isPlaying;
        final total = (active ? state.duration : null) ?? widget.total;
        final position = active ? state.position : Duration.zero;
        final totalMs = (total?.inMilliseconds ?? 0).toDouble();
        final progress = totalMs <= 0
            ? 0.0
            : (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.audiotrack_outlined,
                  size: AppSizes.emptyStateIcon,
                  color: muted,
                ),
                const SizedBox(height: AppSpacing.xl),
                Slider(
                  value: progress,
                  onChanged: active && totalMs > 0
                      ? (value) => _cubit.seek(
                          widget.messageId,
                          Duration(milliseconds: (value * totalMs).round()),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(position),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                      Text(
                        total == null ? '--:--' : formatDuration(total),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                IconButton.filled(
                  tooltip: playing ? 'Pause' : 'Play',
                  iconSize: AppSizes.avatarLarge / 2,
                  onPressed: () => _cubit.toggle(
                    widget.messageId,
                    widget.path,
                    total: widget.total,
                  ),
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
