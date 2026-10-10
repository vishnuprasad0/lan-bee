import '../repositories/settings_repository.dart';

/// Persists the last-read time for a peer's conversation.
class SaveLastRead {
  const SaveLastRead(this._repo);
  final SettingsRepository _repo;
  Future<void> call(String peerId, DateTime time) =>
      _repo.setLastRead(peerId, time);
}
