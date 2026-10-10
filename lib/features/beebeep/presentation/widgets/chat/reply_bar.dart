import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_spacing.dart';
import 'package:beebeep/app/theme/app_sizes.dart';

/// Strip above the composer while replying: name, quoted snippet, close.
class ReplyBar extends StatelessWidget {
  const ReplyBar({
    super.key,
    required this.name,
    required this.snippet,
    required this.onClose,
  });
  final String name;
  final String snippet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: theme.colorScheme.primary),
                child: const SizedBox(width: AppSpacing.xs),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Replying to $name',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cancel reply',
                constraints: const BoxConstraints(
                  minWidth: AppSizes.tapTarget,
                  minHeight: AppSizes.tapTarget,
                ),
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
