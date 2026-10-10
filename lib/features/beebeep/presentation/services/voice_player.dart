import 'package:audioplayers/audioplayers.dart';

/// Minimal player surface used by the playback cubit, so tests can fake it.
abstract interface class VoicePlayer {
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<void> get completeStream;
  Future<void> play(String path);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

/// `audioplayers` implementation. One shared instance plays one note at a
/// time.
class AudioVoicePlayer implements VoicePlayer {
  AudioVoicePlayer() : _player = AudioPlayer();
  final AudioPlayer _player;

  @override
  Stream<Duration> get positionStream => _player.onPositionChanged;

  @override
  Stream<Duration> get durationStream => _player.onDurationChanged;

  @override
  Stream<void> get completeStream => _player.onPlayerComplete;

  @override
  Future<void> play(String path) => _player.play(DeviceFileSource(path));

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
