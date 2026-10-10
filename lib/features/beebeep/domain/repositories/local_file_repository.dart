import 'dart:typed_data';

/// Access to files already on this device (sent or received attachments).
abstract interface class LocalFileRepository {
  /// True when a file exists at [path].
  Future<bool> exists(String path);

  /// File bytes, or null when the file is missing or unreadable.
  Future<Uint8List?> readBytes(String path);
}
