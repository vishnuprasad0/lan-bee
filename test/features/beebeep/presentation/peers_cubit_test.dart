import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/connect_to_peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/load_cached_peers.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/load_peer_display_names.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/refresh_discovery.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/save_cached_peers.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/save_peer_display_name.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/start_discovery.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/stop_discovery.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/watch_peer_identities.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/watch_peers.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/peers/peers_cubit.dart';

import '../../../support/test_harness.dart';

void main() {
  const desktop = Peer(
    id: '192.168.0.159:6475',
    displayName: 'vishnu',
    host: '192.168.0.159',
    port: 6475,
  );

  late FakePeerDiscoveryRepository discovery;
  late FakeConnectionRepository connection;
  late PeersCubit cubit;

  setUp(() {
    discovery = FakePeerDiscoveryRepository(onlinePeers: const [desktop]);
    connection = FakeConnectionRepository();
    final cache = FakePeerCacheRepository();
    cubit = PeersCubit(
      startDiscovery: StartDiscovery(discovery),
      stopDiscovery: StopDiscovery(discovery),
      refreshDiscovery: RefreshDiscovery(discovery),
      connectToPeer: ConnectToPeer(connection),
      watchPeers: WatchPeers(discovery),
      watchPeerIdentities: WatchPeerIdentities(connection),
      loadCachedPeers: LoadCachedPeers(cache),
      saveCachedPeers: SaveCachedPeers(cache),
      loadPeerDisplayNames: LoadPeerDisplayNames(cache),
      savePeerDisplayName: SavePeerDisplayName(cache),
    );
  });

  tearDown(() => cubit.close());

  test('connects to a discovered peer, like BeeBEEP desktop does', () async {
    await cubit.start();
    await pumpEventQueue();

    expect(connection.connected, [desktop]);
  });

  test('does not redial the same peer within the backoff window', () async {
    await cubit.start();
    await pumpEventQueue();
    await cubit.restart();
    await pumpEventQueue();

    expect(discovery.refreshCount, 1);
    expect(connection.connected, [desktop]);
  });

  test('refresh keeps discovery running instead of stop and start', () async {
    await cubit.start();
    await cubit.restart();

    expect(discovery.stopCount, 0);
    expect(discovery.startCount, 1);
    expect(cubit.state.isDiscovering, isTrue);
  });
}
