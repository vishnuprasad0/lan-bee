import 'package:flutter/material.dart';

/// Semantic colours that do not fit a [ColorScheme] role: chat bubbles,
/// presence statuses and the avatar palette. Read with `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bubbleOutgoing,
    required this.bubbleIncoming,
    required this.bubbleSelected,
    required this.statusOnline,
    required this.statusAway,
    required this.statusBusy,
    required this.statusOffline,
    required this.avatarPalette,
    required this.avatarForeground,
    required this.previewSurface,
    required this.onPreviewSurface,
    required this.previewScrim,
    required this.svgSurface,
  });
  final Color bubbleOutgoing;
  final Color bubbleIncoming;

  /// Overlay painted over a selected message (already carries its alpha).
  final Color bubbleSelected;
  final Color statusOnline;
  final Color statusAway;
  final Color statusBusy;
  final Color statusOffline;

  /// Eight muted hues; an avatar picks one by a stable hash of the peer id.
  final List<Color> avatarPalette;

  /// Initials colour on top of [avatarPalette].
  final Color avatarForeground;

  /// File preview page background (near black, in both themes).
  final Color previewSurface;

  /// Text and icons on [previewSurface] and on [previewScrim].
  final Color onPreviewSurface;

  /// Translucent chip behind the footer drawn over an image thumbnail.
  final Color previewScrim;

  /// Light canvas for SVG previews (SVGs often have transparent backgrounds).
  final Color svgSurface;
  static const AppColors light = AppColors(
    bubbleOutgoing: Color(0xFFFFE7A8),
    bubbleIncoming: Color(0xFFFFFFFF),
    bubbleSelected: Color(0x59F5C451),
    statusOnline: Color(0xFF2E9E4F),
    statusAway: Color(0xFFD9A000),
    statusBusy: Color(0xFFD64545),
    statusOffline: Color(0xFF9A958A),
    avatarPalette: <Color>[
      Color(0xFF8A5A44),
      Color(0xFF4F7A5A),
      Color(0xFF4A6FA5),
      Color(0xFF7B5EA7),
      Color(0xFFA05165),
      Color(0xFF3F7F83),
      Color(0xFF8A6D1F),
      Color(0xFF5A6B7B),
    ],
    avatarForeground: Color(0xFFFFFFFF),
    previewSurface: Color(0xFF101010),
    onPreviewSurface: Color(0xFFFFFFFF),
    previewScrim: Color(0x99000000),
    svgSurface: Color(0xFFFFFFFF),
  );
  static const AppColors dark = AppColors(
    bubbleOutgoing: Color(0xFF5A4410),
    bubbleIncoming: Color(0xFF2A251C),
    bubbleSelected: Color(0x40FFC24A),
    statusOnline: Color(0xFF4CC26E),
    statusAway: Color(0xFFF2C200),
    statusBusy: Color(0xFFF06A6A),
    statusOffline: Color(0xFF77726A),
    avatarPalette: <Color>[
      Color(0xFF6E4636),
      Color(0xFF3D6148),
      Color(0xFF3B5A85),
      Color(0xFF62497F),
      Color(0xFF84404F),
      Color(0xFF316568),
      Color(0xFF6E5518),
      Color(0xFF485662),
    ],
    avatarForeground: Color(0xFFFFFFFF),
    previewSurface: Color(0xFF101010),
    onPreviewSurface: Color(0xFFFFFFFF),
    previewScrim: Color(0x99000000),
    svgSurface: Color(0xFFFFFFFF),
  );
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }

  /// Stable across runs and platforms (unlike `String.hashCode`): FNV-1a.
  static int stableHash(String value) {
    var hash = 0x811C9DC5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  Color avatarColorFor(String peerId) {
    return avatarPalette[stableHash(peerId) % avatarPalette.length];
  }

  @override
  AppColors copyWith({
    Color? bubbleOutgoing,
    Color? bubbleIncoming,
    Color? bubbleSelected,
    Color? statusOnline,
    Color? statusAway,
    Color? statusBusy,
    Color? statusOffline,
    List<Color>? avatarPalette,
    Color? avatarForeground,
    Color? previewSurface,
    Color? onPreviewSurface,
    Color? previewScrim,
    Color? svgSurface,
  }) {
    return AppColors(
      bubbleOutgoing: bubbleOutgoing ?? this.bubbleOutgoing,
      bubbleIncoming: bubbleIncoming ?? this.bubbleIncoming,
      bubbleSelected: bubbleSelected ?? this.bubbleSelected,
      statusOnline: statusOnline ?? this.statusOnline,
      statusAway: statusAway ?? this.statusAway,
      statusBusy: statusBusy ?? this.statusBusy,
      statusOffline: statusOffline ?? this.statusOffline,
      avatarPalette: avatarPalette ?? this.avatarPalette,
      avatarForeground: avatarForeground ?? this.avatarForeground,
      previewSurface: previewSurface ?? this.previewSurface,
      onPreviewSurface: onPreviewSurface ?? this.onPreviewSurface,
      previewScrim: previewScrim ?? this.previewScrim,
      svgSurface: svgSurface ?? this.svgSurface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bubbleOutgoing: Color.lerp(bubbleOutgoing, other.bubbleOutgoing, t)!,
      bubbleIncoming: Color.lerp(bubbleIncoming, other.bubbleIncoming, t)!,
      bubbleSelected: Color.lerp(bubbleSelected, other.bubbleSelected, t)!,
      statusOnline: Color.lerp(statusOnline, other.statusOnline, t)!,
      statusAway: Color.lerp(statusAway, other.statusAway, t)!,
      statusBusy: Color.lerp(statusBusy, other.statusBusy, t)!,
      statusOffline: Color.lerp(statusOffline, other.statusOffline, t)!,
      avatarPalette: <Color>[
        for (var i = 0; i < avatarPalette.length; i++)
          Color.lerp(
            avatarPalette[i],
            other.avatarPalette[i % other.avatarPalette.length],
            t,
          )!,
      ],
      avatarForeground: Color.lerp(
        avatarForeground,
        other.avatarForeground,
        t,
      )!,
      previewSurface: Color.lerp(previewSurface, other.previewSurface, t)!,
      onPreviewSurface: Color.lerp(
        onPreviewSurface,
        other.onPreviewSurface,
        t,
      )!,
      previewScrim: Color.lerp(previewScrim, other.previewScrim, t)!,
      svgSurface: Color.lerp(svgSurface, other.svgSurface, t)!,
    );
  }
}
