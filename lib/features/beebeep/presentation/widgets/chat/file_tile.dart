import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/services/file_format.dart';
import '../../../domain/services/preview_kind.dart';
import '../../services/file_actions.dart';
import '../common/file_type_icon.dart';
import '../common/open_preview.dart';

/// File attachment inside a bubble: type icon, name, size. Tap opens it. A
/// file that is gone from this device is greyed out.
class FileTile extends StatelessWidget {
  const FileTile({super.key, required this.message, this.onTapEnabled = true});
  final ChatMessage message;

  /// False in selection mode, where taps toggle selection instead.
  final bool onTapEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final available = localFileExists(message.filePath);
    final muted = theme.colorScheme.onSurfaceVariant;
    final name = message.fileName ?? 'File';
    return Semantics(
      button: available,
      label: available ? 'File $name. Tap to open.' : 'File $name. Missing.',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: available && onTapEnabled
            ? () => previewKindFor(name) == PreviewKind.none
                  ? openLocalFile(context, message.filePath)
                  : openFilePreview(context, message)
            : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                fileIconFor(name),
                color: available ? theme.colorScheme.onSurface : muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: available ? null : muted,
                      ),
                    ),
                    Text(
                      available
                          ? (message.fileSize == null
                                ? ''
                                : formatFileSize(message.fileSize!))
                          : 'File no longer on this device',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
