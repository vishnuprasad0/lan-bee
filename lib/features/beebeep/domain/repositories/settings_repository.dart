/// Repository for app settings.
abstract interface class SettingsRepository {
  /// Returns the stored display name, if any.
  Future<String?> getDisplayName();

  /// Persists the display name.
  Future<void> setDisplayName(String name);

  /// Returns the last-read time of every conversation, keyed by peer id.
  Future<Map<String, DateTime>> getLastReadTimes();

  /// Persists the last-read time for one conversation.
  Future<void> setLastRead(String peerId, DateTime time);
}
