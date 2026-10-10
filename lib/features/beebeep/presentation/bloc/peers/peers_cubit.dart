import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/cached_peer.dart';
import '../../../domain/entities/peer.dart';
import '../../../domain/use_cases/connect_to_peer.dart';
import '../../../domain/use_cases/load_cached_peers.dart';
import '../../../domain/use_cases/load_peer_display_names.dart';
import '../../../domain/use_cases/save_cached_peers.dart';
import '../../../domain/use_cases/save_peer_display_name.dart';
import '../../../domain/use_cases/watch_peer_identities.dart';
import '../../../domain/use_cases/start_discovery.dart';
import '../../../domain/use_cases/refresh_discovery.dart';
import '../../../domain/use_cases/stop_discovery.dart';
import '../../../domain/use_cases/watch_peers.dart';
import 'peer_presence.dart';
import 'peers_state.dart';

class PeersCubit extends Cubit<PeersState> {
  PeersCubit({
    required StartDiscovery startDiscovery,
    required StopDiscovery stopDiscovery,
    required RefreshDiscovery refreshDiscovery,
    required ConnectToPeer connectToPeer,
    required WatchPeers watchPeers,
    required WatchPeerIdentities watchPeerIdentities,
    required LoadCachedPeers loadCachedPeers,
    required SaveCachedPeers saveCachedPeers,
    required LoadPeerDisplayNames loadPeerDisplayNames,
    required SavePeerDisplayName savePeerDisplayName,
  }) : _startDiscovery = startDiscovery,
       _stopDiscovery = stopDiscovery,
       _refreshDiscovery = refreshDiscovery,
       _connectToPeer = connectToPeer,
       _watchPeers = watchPeers,
       _watchPeerIdentities = watchPeerIdentities,
       _loadCachedPeers = loadCachedPeers,
       _saveCachedPeers = saveCachedPeers,
       _loadPeerDisplayNames = loadPeerDisplayNames,
       _savePeerDisplayName = savePeerDisplayName,
       super(const PeersState.initial());

  final StartDiscovery _startDiscovery;
  final StopDiscovery _stopDiscovery;
  final RefreshDiscovery _refreshDiscovery;
  final ConnectToPeer _connectToPeer;

  /// Last auto-connect attempt per peer id, so a flapping peer is not dialled
  /// on every discovery event.
  final Map<String, DateTime> _lastConnectAttempt = <String, DateTime>{};
  static const Duration _reconnectBackoff = Duration(seconds: 30);

  /// Re-dials online peers whose chat connection dropped (the peer stays in
  /// the discovery list, so no discovery event would trigger a reconnect).
  Timer? _reconnectTimer;
  static const Duration _reconnectInterval = Duration(seconds: 20);
  List<Peer> _onlinePeers = const <Peer>[];
  final WatchPeers _watchPeers;
  final WatchPeerIdentities _watchPeerIdentities;
  final LoadCachedPeers _loadCachedPeers;
  final SaveCachedPeers _saveCachedPeers;
  final LoadPeerDisplayNames _loadPeerDisplayNames;
  final SavePeerDisplayName _savePeerDisplayName;

  final Map<String, String> _displayNameByPeerId = <String, String>{};
  final Map<String, CachedPeer> _cachedPeersById = <String, CachedPeer>{};

  StreamSubscription? _peersSub;
  StreamSubscription? _identitiesSub;

  Future<void> start() async {
    if (state.isDiscovering) return;

    emit(state.copyWith(isDiscovering: true, errorMessage: null));

    if (_displayNameByPeerId.isEmpty || _cachedPeersById.isEmpty) {
      try {
        final cachedPeers = await _loadCachedPeers();
        _cachedPeersById.addAll(cachedPeers);

        if (_displayNameByPeerId.isEmpty) {
          final cached = await _loadPeerDisplayNames();
          _displayNameByPeerId.addAll(cached);
        }
      } catch (e) {
        emit(state.copyWith(errorMessage: e.toString()));
      }
    }

    if (_cachedPeersById.isNotEmpty && state.peers.isEmpty) {
      emit(state.copyWith(peers: _buildPresence(const <Peer>[])));
    }

    _peersSub ??= _watchPeers().listen(
      (peers) => _handlePeersUpdate(peers),
      onError: (e) => emit(state.copyWith(errorMessage: e.toString())),
    );

    _identitiesSub ??= _watchPeerIdentities().listen((identity) {
      final trimmed = identity.displayName.trim();
      if (trimmed.isEmpty) return;

      _displayNameByPeerId[identity.peerId] = trimmed;
      _updateCachedDisplayName(identity.peerId, trimmed);
      emit(state.copyWith(peers: _applyDisplayNames(state.peers)));
      unawaited(
        _savePeerDisplayName(peerId: identity.peerId, displayName: trimmed),
      );
    }, onError: (e) => emit(state.copyWith(errorMessage: e.toString())));

    try {
      await _startDiscovery();
    } catch (e) {
      emit(state.copyWith(isDiscovering: false, errorMessage: e.toString()));
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(
      _reconnectInterval,
      (_) => _autoConnect(_onlinePeers),
    );
  }

  Future<void> stop() async {
    if (!state.isDiscovering) return;

    emit(state.copyWith(isDiscovering: false, errorMessage: null));
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    try {
      await _stopDiscovery();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  /// Pull to refresh and Retry: looks again without clearing the list.
  /// Starts discovery if it is off.
  Future<void> restart() async {
    if (!state.isDiscovering) {
      await start();
      return;
    }
    try {
      await _refreshDiscovery();
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() async {
    _reconnectTimer?.cancel();
    await _peersSub?.cancel();
    await _identitiesSub?.cancel();
    return super.close();
  }

  void _handlePeersUpdate(List<Peer> peers) {
    _onlinePeers = peers;
    emit(state.copyWith(peers: _buildPresence(peers)));
    _autoConnect(peers);
  }

  /// BeeBEEP desktop connects to every peer it discovers; doing the same puts
  /// this device in the desktop user list without opening a chat first.
  void _autoConnect(List<Peer> peers) {
    final now = DateTime.now();
    for (final peer in peers) {
      final last = _lastConnectAttempt[peer.id];
      if (last != null && now.difference(last) < _reconnectBackoff) continue;
      _lastConnectAttempt[peer.id] = now;
      unawaited(_connectToPeer(peer).catchError((Object _) {}));
    }
  }

  List<PeerPresence> _buildPresence(List<Peer> peers) {
    final now = DateTime.now();
    final onlineById = <String, Peer>{
      for (final peer in peers) peer.id: _applyDisplayName(peer),
    };

    final updated = <CachedPeer>[];
    for (final peer in onlineById.values) {
      final existing = _cachedPeersById[peer.id];
      final lastSeen =
          existing?.lastSeen ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (now.difference(lastSeen).inSeconds < 15 && existing != null) {
        continue;
      }

      final cached = CachedPeer(
        peerId: peer.id,
        displayName: peer.displayName,
        host: peer.host,
        port: peer.port,
        lastSeen: now,
      );
      _cachedPeersById[peer.id] = cached;
      updated.add(cached);
    }

    if (updated.isNotEmpty) {
      unawaited(_saveCachedPeers(updated));
    }

    final presences = <PeerPresence>[];
    for (final cached in _cachedPeersById.values) {
      final onlinePeer = onlineById[cached.peerId];
      final peer = onlinePeer ?? _peerFromCached(cached);
      presences.add(
        PeerPresence(
          peer: _applyDisplayName(peer),
          isOnline: onlinePeer != null,
          lastSeen: cached.lastSeen == DateTime.fromMillisecondsSinceEpoch(0)
              ? null
              : cached.lastSeen,
        ),
      );
    }

    presences.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      return a.peer.displayName.compareTo(b.peer.displayName);
    });

    return presences;
  }

  List<PeerPresence> _applyDisplayNames(List<PeerPresence> peers) {
    if (_displayNameByPeerId.isEmpty) return peers;

    return peers
        .map((presence) {
          final peer = presence.peer;
          final override = _displayNameByPeerId[peer.id];
          if (override == null || override == peer.displayName) return presence;
          return PeerPresence(
            peer: Peer(
              id: peer.id,
              displayName: override,
              host: peer.host,
              port: peer.port,
            ),
            isOnline: presence.isOnline,
            lastSeen: presence.lastSeen,
          );
        })
        .toList(growable: false);
  }

  Peer _applyDisplayName(Peer peer) {
    final override = _displayNameByPeerId[peer.id];
    if (override == null || override == peer.displayName) return peer;
    return Peer(
      id: peer.id,
      displayName: override,
      host: peer.host,
      port: peer.port,
    );
  }

  Peer _peerFromCached(CachedPeer cached) {
    return Peer(
      id: cached.peerId,
      displayName: cached.displayName,
      host: cached.host,
      port: cached.port,
    );
  }

  void _updateCachedDisplayName(String peerId, String displayName) {
    final existing = _cachedPeersById[peerId];
    if (existing == null) return;
    _cachedPeersById[peerId] = existing.copyWith(displayName: displayName);
  }
}
