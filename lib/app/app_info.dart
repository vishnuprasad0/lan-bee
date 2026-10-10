/// Static app identity shown on the About screen.
abstract final class AppInfo {
  static const String name = 'LAN Bee';

  /// Keep in sync with `version:` in pubspec.yaml until a version plugin is
  /// justified.
  static const String version = '1.0.0';
  static const String compatibilityNote =
      'Compatible with BeeBEEP desktop. Not affiliated with the BeeBEEP '
      'project.';
}
