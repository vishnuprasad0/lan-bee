import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_colors.dart';
import 'package:beebeep/app/theme/app_sizes.dart';

/// Presence indicator: filled when online, hollow ring when offline. Shape
/// differs as well as colour, and the dot carries a semantic label.
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    required this.isOnline,
    this.size = AppSizes.statusDot,
  });

  final bool isOnline;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = isOnline ? colors.statusOnline : colors.statusOffline;
    final surface = Theme.of(context).colorScheme.surface;

    return Semantics(
      label: isOnline ? 'Online' : 'Offline',
      container: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOnline ? color : surface,
            border: isOnline ? null : Border.all(color: color, width: 2),
          ),
        ),
      ),
    );
  }
}
