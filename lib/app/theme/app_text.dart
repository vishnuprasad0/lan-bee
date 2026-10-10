import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Material 3 type scale. Uses the platform default family (Roboto on
/// Android); no runtime font fetching so the app works offline.
abstract final class AppText {
  /// Platform monospace family for the text file preview.
  static const String monospaceFamily = 'monospace';

  static TextTheme textTheme(ColorScheme scheme) {
    final typography = Typography.material2021(
      platform: defaultTargetPlatform,
      colorScheme: scheme,
    );
    final base = scheme.brightness == Brightness.dark
        ? typography.white
        : typography.black;
    return base
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
        .copyWith(
          titleMedium: base.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
          labelSmall: base.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        );
  }
}
