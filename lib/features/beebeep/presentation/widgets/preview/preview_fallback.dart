import 'package:flutter/material.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/services/file_format.dart';
import '../common/file_type_icon.dart';

/// Info card for a file the app cannot preview, or that is gone from this
/// device: type icon, name, size, and Open with / Share buttons.
class PreviewFallback extends StatelessWidget {
  const PreviewFallback({
    super.key,
    required this.name,
    required this.size,
    required this.available,
    required this.onOpenWith,
    required this.onShare,
  });
  final String name;
  final int? size;
  final bool available;
  final VoidCallback onOpenWith;
  final VoidCallback onShare;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              available ? fileIconFor(name) : Icons.folder_off_outlined,
              size: AppSizes.emptyStateIcon,
              color: muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (size != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatFileSize(size!),
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
            if (!available) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'File no longer on this device',
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
            if (available) ...[
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton.icon(
                    onPressed: onOpenWith,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open with'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
