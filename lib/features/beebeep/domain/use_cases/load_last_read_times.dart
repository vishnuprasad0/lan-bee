import '../repositories/settings_repository.dart';

/// Loads the last-read time per peer id.
class LoadLastReadTimes {
  const LoadLastReadTimes(this._repo);
  final SettingsRepository _repo;
  Future<Map<String, DateTime>> call() => _repo.getLastReadTimes();
}
