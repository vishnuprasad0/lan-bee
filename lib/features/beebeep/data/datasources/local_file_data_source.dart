import 'dart:io';
import 'dart:typed_data';

/// Reads files that already live on this device.
class LocalFileDataSource {
  const LocalFileDataSource();

  Future<bool> exists(String path) => File(path).exists();
  Future<Uint8List?> readBytes(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }
}
