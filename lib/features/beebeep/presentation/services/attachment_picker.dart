import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A file chosen by the user, fully read into memory for sending.
class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.bytes,
    required this.size,
    required this.path,
  });
  final String name;
  final Uint8List bytes;
  final int size;
  final String? path;
}

/// Shows the system file picker. Returns null when cancelled; throws
/// [FileSystemException] when the file cannot be read.
Future<PickedAttachment?> pickAttachment() async {
  final result = await FilePicker.platform.pickFiles(
    withData: true,
    withReadStream: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.single;
  var bytes = file.bytes;
  if (bytes == null && file.readStream != null) {
    final builder = BytesBuilder();
    await for (final chunk in file.readStream!) {
      builder.add(chunk);
    }
    bytes = builder.takeBytes();
  }

  if (bytes == null && file.path != null) {
    bytes = await File(file.path!).readAsBytes();
  }

  if (bytes == null) {
    throw const FileSystemException('Failed to read file bytes');
  }

  return PickedAttachment(
    name: file.name,
    bytes: bytes,
    size: file.size > 0 ? file.size : bytes.length,
    path: file.path,
  );
}
