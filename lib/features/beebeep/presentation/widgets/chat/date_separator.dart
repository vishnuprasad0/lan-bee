import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/services/chat_timeline.dart';

/// Centered day chip: Today, Yesterday, Mon 5 Oct, 5 Oct 2025.
class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.day, required this.now});
  final DateTime day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Semantics(
          header: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: AppRadii.chipRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                daySeparatorLabel(day, now: now),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
