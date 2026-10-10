import 'package:equatable/equatable.dart';

class VoicePlaybackState extends Equatable {
  const VoicePlaybackState({
    this.messageId,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
  });

  /// The voice message that currently owns the player, if any.
  final String? messageId;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;

  @override
  List<Object?> get props => [messageId, isPlaying, position, duration];
}
