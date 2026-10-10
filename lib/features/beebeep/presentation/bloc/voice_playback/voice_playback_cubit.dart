import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/voice_player.dart';

import 'voice_playback_state.dart';

/// Shared playback controller: only one voice note plays at a time. Starting
/// another note replaces the current one.
class VoicePlaybackCubit extends Cubit<VoicePlaybackState> {
  VoicePlaybackCubit(this._player) : super(const VoicePlaybackState()) {
    _subs = [
      _player.positionStream.listen((p) {
        if (state.messageId != null) emit(_with(position: p));
      }),
      _player.durationStream.listen((d) {
        if (state.messageId != null) emit(_with(duration: d));
      }),
      _player.completeStream.listen((_) {
        if (state.messageId != null) {
          emit(
            VoicePlaybackState(
              messageId: state.messageId,
              duration: state.duration,
            ),
          );
        }
      }),
    ];
  }

  final VoicePlayer _player;
  late final List<StreamSubscription<Object?>> _subs;
  VoicePlaybackState _with({Duration? position, Duration? duration}) {
    return VoicePlaybackState(
      messageId: state.messageId,
      isPlaying: state.isPlaying,
      position: position ?? state.position,
      duration: duration ?? state.duration,
    );
  }

  /// Play, pause, or resume [messageId] (file at [path]).
  Future<void> toggle(String messageId, String path, {Duration? total}) async {
    try {
      if (state.messageId == messageId) {
        if (state.isPlaying) {
          await _player.pause();
          emit(_withPlaying(false));
        } else {
          final finished =
              state.duration != null && state.position >= state.duration!;
          if (finished || state.position == Duration.zero) {
            await _player.play(path);
          } else {
            await _player.resume();
          }
          emit(_withPlaying(true));
        }
        return;
      }
      await _player.stop();
      emit(VoicePlaybackState(messageId: messageId, duration: total));
      await _player.play(path);
      emit(_withPlaying(true));
    } on Object catch (error) {
      debugPrint('Voice playback failed: $error');
      emit(const VoicePlaybackState());
    }
  }

  VoicePlaybackState _withPlaying(bool playing) {
    return VoicePlaybackState(
      messageId: state.messageId,
      isPlaying: playing,
      position: state.position,
      duration: state.duration,
    );
  }

  Future<void> seek(String messageId, Duration position) async {
    if (state.messageId != messageId) return;
    await _player.seek(position);
    emit(_with(position: position));
  }

  /// Pauses [messageId] if it is the one playing (for example when leaving
  /// the audio preview). Keeps the position so playback can resume.
  Future<void> pauseIfPlaying(String messageId) async {
    if (state.messageId != messageId || !state.isPlaying) return;
    try {
      await _player.pause();
      emit(_withPlaying(false));
    } on Object catch (error) {
      debugPrint('Voice pause failed: $error');
    }
  }

  /// Stops playback if [messageId] is the current note (for example when the
  /// message is deleted).
  Future<void> stopIfPlaying(Iterable<String> messageIds) async {
    final current = state.messageId;
    if (current == null || !messageIds.contains(current)) return;
    await _player.stop();
    emit(const VoicePlaybackState());
  }

  @override
  Future<void> close() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    await _player.dispose();
    return super.close();
  }
}
