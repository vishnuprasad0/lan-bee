import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_spacing.dart';

/// Quoted text at the top of a bubble: bar in primary, two lines at most.
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadiusDirectional.horizontal(
                  start: Radius.circular(AppRadii.card),
                ),
              ),
              child: const SizedBox(width: AppSpacing.xs),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs + 2,
                ),
                child: Semantics(
                  label: 'Quoted message: $text',
                  child: ExcludeSemantics(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
