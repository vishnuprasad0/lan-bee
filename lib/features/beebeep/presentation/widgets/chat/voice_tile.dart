import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/services/file_format.dart';
import '../../bloc/voice_playback/voice_playback_cubit.dart';
import '../../bloc/voice_playback/voice_playback_state.dart';
import '../../services/file_actions.dart';

/// Voice note: play/pause, seekable progress, elapsed / total. Only one note
/// plays at a time (see [VoicePlaybackCubit]).
class VoiceTile extends StatelessWidget {
  const VoiceTile({super.key, required this.message, this.enabled = true});
  final ChatMessage message;

  /// False in selection mode, where taps toggle selection instead.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = localFileExists(message.filePath);
    final muted = theme.colorScheme.onSurfaceVariant;
    if (!available) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_off_outlined, color: muted),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              'File no longer on this device',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      );
    }
    return BlocBuilder<VoicePlaybackCubit, VoicePlaybackState>(
      buildWhen: (previous, current) =>
          previous.messageId == message.id || current.messageId == message.id,
      builder: (context, state) {
        final active = state.messageId == message.id;
        final playing = active && state.isPlaying;
        final total = (active ? state.duration : null) ?? message.duration;
        final position = active ? state.position : Duration.zero;
        final totalMs = (total?.inMilliseconds ?? 0).toDouble();
        final progress = totalMs <= 0
            ? 0.0
            : (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
        return SizedBox(
          width: 240,
          child: Row(
            children: [
              IconButton(
                tooltip: playing ? 'Pause voice message' : 'Play voice message',
                constraints: const BoxConstraints(
                  minWidth: AppSizes.tapTarget,
                  minHeight: AppSizes.tapTarget,
                ),
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                onPressed: enabled
                    ? () => context.read<VoicePlaybackCubit>().toggle(
                        message.id,
                        message.filePath!,
                        total: message.duration,
                      )
                    : null,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: enabled && active && totalMs > 0
                            ? (value) =>
                                  context.read<VoicePlaybackCubit>().seek(
                                    message.id,
                                    Duration(
                                      milliseconds: (value * totalMs).round(),
                                    ),
                                  )
                            : null,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: Text(
                          '${formatDuration(position)} / '
                          '${total == null ? '--:--' : formatDuration(total)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
