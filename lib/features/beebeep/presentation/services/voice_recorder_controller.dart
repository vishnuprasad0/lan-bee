import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// record is provided transitively by the vendored voice_message_recorder.
// ignore: depend_on_referenced_packages
import 'package:record/record.dart';

/// A finished recording.
class RecordedVoice {
  const RecordedVoice({required this.file, required this.duration});
  final File file;
  final Duration duration;
}

/// Wraps the microphone recorder: start, tick the elapsed time, stop with or
/// without keeping the file.
class VoiceRecorderController extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  DateTime? _startedAt;
  String? _path;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  bool get isRecording => _isRecording;

  Duration get elapsed => _elapsed;

  /// Returns false when the microphone permission is missing.
  Future<bool> start() async {
    if (_isRecording) return true;
    if (!await _recorder.hasPermission()) return false;

    // Kept under beebeep_files/ so the note survives cache clean-ups and can
    // be played, shared, or forwarded later.
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/beebeep_files');
    await dir.create(recursive: true);
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _startedAt = DateTime.now();
    _path = path;
    _isRecording = true;
    _elapsed = Duration.zero;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _elapsed = DateTime.now().difference(_startedAt!);
      notifyListeners();
    });
    notifyListeners();
    return true;
  }

  /// Stops recording. Returns the recording when [keep] is true, the file
  /// exists, and it lasted at least [minDuration]; otherwise deletes it and
  /// returns null.
  Future<RecordedVoice?> stop({
    required bool keep,
    Duration minDuration = Duration.zero,
  }) async {
    if (!_isRecording) return null;
    _timer?.cancel();
    final duration = DateTime.now().difference(_startedAt!);
    final path = _path;
    _isRecording = false;
    _startedAt = null;
    _path = null;
    _elapsed = Duration.zero;
    notifyListeners();
    try {
      await _recorder.stop();
    } on Object catch (error) {
      debugPrint('Recorder stop failed: $error');
    }
    if (path == null) return null;
    final file = File(path);
    if (!keep || duration < minDuration || !file.existsSync()) {
      if (file.existsSync()) await file.delete();
      return null;
    }
    return RecordedVoice(file: file, duration: duration);
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }
}
