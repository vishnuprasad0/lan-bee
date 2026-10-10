import 'package:flutter/material.dart';
import '../../../domain/entities/chat_message.dart';
import '../../pages/file_preview_page.dart';

/// Opens the in-app preview for the file of [message].
Future<void> openFilePreview(BuildContext context, ChatMessage message) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => FilePreviewPage(message: message)),
  );
}
