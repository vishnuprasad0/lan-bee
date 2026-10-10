import 'package:flutter/material.dart';

import '../../../domain/entities/chat_message.dart';
import '../../../domain/services/file_format.dart';

/// Icon for a file by extension, or a mic for voice messages.
IconData fileIconFor(String? fileName, {MessageType? type}) {
  if (type == MessageType.voice) return Icons.mic_none;
  switch (fileKindOf(fileName)) {
    case FileKind.pdf:
      return Icons.picture_as_pdf_outlined;
    case FileKind.image:
      return Icons.image_outlined;
    case FileKind.audio:
      return Icons.audiotrack_outlined;
    case FileKind.archive:
      return Icons.folder_zip_outlined;
    case FileKind.generic:
      return Icons.insert_drive_file_outlined;
  }
}
