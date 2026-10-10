import 'dart:io';

import 'package:flutter/material.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/services/file_format.dart';
import '../../domain/services/preview_kind.dart';
import '../services/file_actions.dart';
import '../services/text_preview_loader.dart';
import '../widgets/preview/audio_preview.dart';
import '../widgets/preview/image_preview.dart';
import '../widgets/preview/preview_fallback.dart';
import '../widgets/preview/text_preview.dart';
import '../widgets/preview/video_preview.dart';

/// In-app viewer for a received or sent file. Needs no storage permission:
/// files live in the app documents directory. Kinds the app cannot show (and
/// files that are gone) get an info card with Open with and Share.
class FilePreviewPage extends StatelessWidget {
  const FilePreviewPage({
    super.key,
    required this.message,
    this.textLimitBytes = defaultTextPreviewBytes,
  });
  final ChatMessage message;

  /// Largest part of a text file that is read.
  final int textLimitBytes;
  @override
  Widget build(BuildContext context) {
    final name = message.fileName ?? 'File';
    final path = message.filePath;
    final available = localFileExists(path);
    final kind = previewKindFor(message.fileName);
    void openWith() => openLocalFile(context, path);
    void share() => shareLocalFile(context, path, name: message.fileName);
    final fallback = PreviewFallback(
      name: name,
      size: message.fileSize,
      available: available,
      onOpenWith: openWith,
      onShare: share,
    );
    final Widget body;
    // video_player has no Windows implementation.
    final unsupported =
        kind == PreviewKind.none ||
        (kind == PreviewKind.video && Platform.isWindows);
    if (!available || unsupported) {
      body = fallback;
    } else {
      body = switch (kind) {
        PreviewKind.image => ImagePreview(
          path: path!,
          heroTag: message.id,
          fallback: fallback,
        ),
        PreviewKind.svg => SvgPreview(
          path: path!,
          heroTag: message.id,
          fallback: fallback,
        ),
        PreviewKind.text => TextPreview(
          path: path!,
          limitBytes: textLimitBytes,
          fallback: fallback,
        ),
        PreviewKind.audio => AudioPreview(
          messageId: message.id,
          path: path!,
          total: message.duration,
        ),
        PreviewKind.video => VideoPreview(path: path!, fallback: fallback),
        PreviewKind.none => fallback,
      };
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (message.fileSize != null)
              Text(
                formatFileSize(message.fileSize!),
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: available ? share : null,
          ),
          IconButton(
            tooltip: 'Open with',
            icon: const Icon(Icons.open_in_new),
            onPressed: available ? openWith : null,
          ),
        ],
      ),
      body: body,
    );
  }
}
