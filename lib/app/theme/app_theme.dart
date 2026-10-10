import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_text.dart';

/// Light and dark Material 3 themes for LAN Bee.
abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    seed: const Color(0xFFE8A317),
    onPrimary: const Color(0xFF1F1A10),
    primaryContainer: const Color(0xFFFFE8B0),
    onPrimaryContainer: const Color(0xFF1F1A10),
    surface: const Color(0xFFFFFBF3),
    surfaceContainer: const Color(0xFFF6EFDF),
    outline: const Color(0xFFE3D7BE),
    error: const Color(0xFFBA1A1A),
    extension: AppColors.light,
  );
  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    seed: const Color(0xFFFFC24A),
    onPrimary: const Color(0xFF2A1F00),
    primaryContainer: const Color(0xFF5A4410),
    onPrimaryContainer: const Color(0xFFFFE8B0),
    surface: const Color(0xFF17140E),
    surfaceContainer: const Color(0xFF221E16),
    outline: const Color(0xFF3A3427),
    error: const Color(0xFFFFB4AB),
    extension: AppColors.dark,
  );
  static ThemeData _build({
    required Brightness brightness,
    required Color seed,
    required Color onPrimary,
    required Color primaryContainer,
    required Color onPrimaryContainer,
    required Color surface,
    required Color surfaceContainer,
    required Color outline,
    required Color error,
    required AppColors extension,
  }) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness)
        .copyWith(
          primary: seed,
          onPrimary: onPrimary,
          primaryContainer: primaryContainer,
          onPrimaryContainer: onPrimaryContainer,
          surface: surface,
          surfaceContainer: surfaceContainer,
          outline: outline,
          outlineVariant: outline,
          error: error,
        );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      textTheme: AppText.textTheme(scheme),
      extensions: <ThemeExtension<dynamic>>[extension],
      dividerTheme: DividerThemeData(color: outline, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainer,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primaryContainer,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.fieldRadius,
          borderSide: BorderSide.none,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
