import 'package:hive/hive.dart';

/// Local settings persistence using Hive.
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._box);
  static const String boxName = 'settings';
  static const String _displayNameKey = 'display_name';
  static const String _lastReadPrefix = 'lastRead:';
  final Box<String> _box;

  /// Returns the last saved display name, if any.
  String? getDisplayName() => _box.get(_displayNameKey);

  /// Persists the display name.
  Future<void> setDisplayName(String name) => _box.put(_displayNameKey, name);

  /// Last-read time per peer id, stored as `lastRead:<peerId>` -> epoch millis.
  Map<String, DateTime> getLastReadTimes() {
    final result = <String, DateTime>{};
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith(_lastReadPrefix)) continue;
      final millis = int.tryParse(_box.get(key) ?? '');
      if (millis == null) continue;
      result[key.substring(_lastReadPrefix.length)] =
          DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return result;
  }

  Future<void> setLastRead(String peerId, DateTime time) => _box.put(
    '$_lastReadPrefix$peerId',
    time.millisecondsSinceEpoch.toString(),
  );
}
