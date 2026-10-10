import '../entities/peer.dart';

abstract interface class PeerDiscoveryRepository {
  Stream<List<Peer>> watchPeers();

  Future<void> start();

  Future<void> stop();

  /// Looks for peers again now without clearing the current list.
  Future<void> refresh();
}
