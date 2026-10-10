import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/services/file_format.dart';
import '../../../domain/services/preview_kind.dart';
import '../../../domain/services/relative_time.dart';
import '../../services/file_actions.dart';
import '../common/file_type_icon.dart';
import '../common/open_preview.dart';
import 'file_thumbnail.dart';

/// One file or voice note in the Files tab: type icon, name, peer, size,
/// time, and a share button. A file that is gone is greyed and not openable.
class FileRow extends StatelessWidget {
  const FileRow({super.key, required this.message, required this.peerName});

  final ChatMessage message;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = localFileExists(message.filePath);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isVoice = message.type == MessageType.voice;
    final name = isVoice ? 'Voice message' : (message.fileName ?? 'File');
    final kind = isVoice ? PreviewKind.none : previewKindFor(message.fileName);

    final detail = <String>[
      if (isVoice && message.duration != null)
        formatDuration(message.duration!),
      if (!isVoice && message.fileSize != null)
        formatFileSize(message.fileSize!),
      formatClock(message.timestamp),
    ].join(', ');

    return ListTile(
      enabled: available,
      leading: available && hasThumbnail(kind)
          ? FileThumbnail(path: message.filePath!, kind: kind)
          : Icon(
              fileIconFor(message.fileName, type: message.type),
              color: available ? theme.colorScheme.onSurface : muted,
            ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: available ? null : muted,
        ),
      ),
      subtitle: Text(
        '${message.isOutgoing ? 'To' : 'From'} $peerName\n'
        '${available ? detail : 'Not on this device'}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      onTap: available ? () => _open(context, kind) : null,
      trailing: IconButton(
        tooltip: 'Share',
        constraints: const BoxConstraints(
          minWidth: AppSizes.tapTarget,
          minHeight: AppSizes.tapTarget,
        ),
        icon: const Icon(Icons.share_outlined),
        onPressed: available
            ? () => shareLocalFile(
                context,
                message.filePath,
                name: message.fileName,
              )
            : null,
      ),
    );
  }

  void _open(BuildContext context, PreviewKind kind) {
    if (message.type == MessageType.voice || kind == PreviewKind.none) {
      openLocalFile(context, message.filePath);
    } else {
      openFilePreview(context, message);
    }
  }
}

/// Date heading between groups of rows.
class FileDayHeader extends StatelessWidget {
  const FileDayHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
