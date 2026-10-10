import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

/// Largest part of a text file the preview reads.
const int defaultTextPreviewBytes = 1024 * 1024;

/// Result of [loadTextPreview].
class TextPreviewData {
  const TextPreviewData({required this.text, required this.truncated});
  final String text;

  /// True when the file is larger than the limit and only its start is shown.
  final bool truncated;
}

/// Reads up to [limitBytes] of the file at [path] and decodes it as UTF-8
/// (malformed bytes become replacement characters), off the UI isolate.
Future<TextPreviewData> loadTextPreview(
  String path, {
  int limitBytes = defaultTextPreviewBytes,
}) {
  return Isolate.run(() => _readTextPreview(path, limitBytes));
}

Future<TextPreviewData> _readTextPreview(String path, int limitBytes) async {
  final file = File(path);
  final length = await file.length();
  final builder = BytesBuilder(copy: false);
  await for (final chunk in file.openRead(0, limitBytes)) {
    builder.add(chunk);
  }
  return TextPreviewData(
    text: utf8.decode(builder.takeBytes(), allowMalformed: true),
    truncated: length > limitBytes,
  );
}
