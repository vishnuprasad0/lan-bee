import '../repositories/peer_discovery_repository.dart';

class RefreshDiscovery {
  const RefreshDiscovery(this._repo);

  final PeerDiscoveryRepository _repo;

  Future<void> call() => _repo.refresh();
}
