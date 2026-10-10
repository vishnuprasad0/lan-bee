import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/app/theme/app_theme.dart';
import 'package:beebeep/features/beebeep/domain/entities/cached_peer.dart';
import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer_identity.dart';
import 'package:beebeep/features/beebeep/domain/entities/received_message.dart';
import 'package:beebeep/features/beebeep/domain/repositories/chat_history_repository.dart';
import 'package:beebeep/features/beebeep/domain/repositories/connection_repository.dart';
import 'package:beebeep/features/beebeep/domain/repositories/local_file_repository.dart';
import 'package:beebeep/features/beebeep/domain/repositories/local_node_repository.dart';
import 'package:beebeep/features/beebeep/domain/repositories/peer_cache_repository.dart';
import 'package:beebeep/features/beebeep/domain/repositories/peer_discovery_repository.dart';
import 'package:beebeep/features/beebeep/domain/repositories/settings_repository.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/connect_to_peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/forward_messages.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/load_cached_peers.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/load_chat_history.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/load_discovery_name.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/load_last_read_times.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/load_peer_display_names.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/save_cached_peers.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/save_chat_history.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/save_last_read.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/save_peer_display_name.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/send_chat_to_peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/send_file_to_peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/send_voice_message_to_peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/start_discovery.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/refresh_discovery.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/stop_discovery.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/update_discovery_name.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/watch_logs.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/watch_peer_identities.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/watch_peers.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/chat/chat_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/logs/logs_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/peers/peers_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/read_state/read_state_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/voice_playback/voice_playback_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/services/voice_player.dart';

/// Discovery fake: emits [onlinePeers] when started.
class FakePeerDiscoveryRepository implements PeerDiscoveryRepository {
  FakePeerDiscoveryRepository({this.onlinePeers = const <Peer>[]});

  final List<Peer> onlinePeers;
  final _controller = StreamController<List<Peer>>.broadcast();
  int startCount = 0;
  int stopCount = 0;

  @override
  Stream<List<Peer>> watchPeers() => _controller.stream;

  @override
  Future<void> start() async {
    startCount++;
    _controller.add(onlinePeers);
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  int refreshCount = 0;

  @override
  Future<void> refresh() async {
    refreshCount++;
    _controller.add(onlinePeers);
  }
}

class FakeConnectionRepository implements ConnectionRepository {
  final _logs = StreamController<String>.broadcast();
  final _identities = StreamController<PeerIdentity>.broadcast();
  final List<Peer> connected = <Peer>[];

  /// Every `sendChat` call in order, as `(peerId, text)`.
  final List<(String, String)> sentChats = <(String, String)>[];

  /// Every `sendFile` call in order, as `(peerId, fileName)`.
  final List<(String, String)> sentFiles = <(String, String)>[];

  @override
  Stream<String> watchLogs() => _logs.stream;

  @override
  Stream<PeerIdentity> watchPeerIdentities() => _identities.stream;

  @override
  Stream<ReceivedMessage> watchReceivedMessages() => const Stream.empty();

  @override
  Future<void> startServer({required int port}) async {}

  @override
  Future<void> stopServer() async {}

  @override
  Future<void> connect(Peer peer) async {
    connected.add(peer);
  }

  @override
  Future<void> sendChat({required Peer peer, required String text}) async {
    sentChats.add((peer.id, text));
  }

  @override
  Future<void> sendFile({
    required Peer peer,
    required String fileName,
    required Uint8List bytes,
    required int fileSize,
    String? mimeType,
  }) async {
    sentFiles.add((peer.id, fileName));
  }

  @override
  Future<void> sendVoiceMessage({
    required Peer peer,
    required String fileName,
    required Uint8List bytes,
    required int fileSize,
    String? mimeType,
    Duration? duration,
  }) async {}

  @override
  Future<void> disconnectAll() async {}
}

/// Pretends the paths in [existing] are on the device.
class FakeLocalFileRepository implements LocalFileRepository {
  FakeLocalFileRepository([this.existing = const <String>{}]);

  final Set<String> existing;

  @override
  Future<bool> exists(String path) async => existing.contains(path);

  @override
  Future<Uint8List?> readBytes(String path) async =>
      existing.contains(path) ? Uint8List.fromList(<int>[1, 2, 3]) : null;
}

/// Voice player that never touches audio hardware.
class FakeVoicePlayer implements VoicePlayer {
  final position = StreamController<Duration>.broadcast();
  final duration = StreamController<Duration>.broadcast();
  final complete = StreamController<void>.broadcast();
  final List<String> played = <String>[];

  @override
  Stream<Duration> get positionStream => position.stream;

  @override
  Stream<Duration> get durationStream => duration.stream;

  @override
  Stream<void> get completeStream => complete.stream;

  @override
  Future<void> play(String path) async => played.add(path);

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class FakeChatHistoryRepository implements ChatHistoryRepository {
  FakeChatHistoryRepository([this.messages = const <ChatMessage>[]]);

  List<ChatMessage> messages;

  @override
  Future<List<ChatMessage>> loadMessages() async => messages;

  @override
  Future<void> saveMessages(List<ChatMessage> messages) async {
    this.messages = messages;
  }
}

class FakePeerCacheRepository implements PeerCacheRepository {
  FakePeerCacheRepository([this.cached = const <String, CachedPeer>{}]);

  final Map<String, CachedPeer> cached;

  @override
  Future<Map<String, CachedPeer>> loadAll() async => {...cached};

  @override
  Future<void> savePeer(CachedPeer peer) async {}

  @override
  Future<void> savePeers(Iterable<CachedPeer> peers) async {}

  @override
  Future<void> saveDisplayName({
    required String peerId,
    required String displayName,
  }) async {}
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({Map<String, DateTime>? lastRead})
    : lastRead = lastRead ?? <String, DateTime>{};

  String? displayName;
  final Map<String, DateTime> lastRead;

  @override
  Future<String?> getDisplayName() async => displayName;

  @override
  Future<void> setDisplayName(String name) async => displayName = name;

  @override
  Future<Map<String, DateTime>> getLastReadTimes() async => {...lastRead};

  @override
  Future<void> setLastRead(String peerId, DateTime time) async {
    lastRead[peerId] = time;
  }
}

class FakeLocalNodeRepository implements LocalNodeRepository {
  @override
  Future<void> updateDisplayName(String name) async {}
}

/// Everything a screen test needs, built from in-memory fakes. No sockets,
/// no Hive.
class TestHarness {
  TestHarness({
    List<Peer> onlinePeers = const <Peer>[],
    Map<String, CachedPeer> cachedPeers = const <String, CachedPeer>{},
    List<ChatMessage> messages = const <ChatMessage>[],
    Map<String, DateTime>? lastRead,
    Set<String> existingFiles = const <String>{},
  }) : discovery = FakePeerDiscoveryRepository(onlinePeers: onlinePeers),
       connection = FakeConnectionRepository(),
       chatHistory = FakeChatHistoryRepository(messages),
       peerCache = FakePeerCacheRepository(cachedPeers),
       settings = FakeSettingsRepository(lastRead: lastRead),
       localFiles = FakeLocalFileRepository(existingFiles),
       voicePlayer = FakeVoicePlayer();

  final FakePeerDiscoveryRepository discovery;
  final FakeConnectionRepository connection;
  final FakeChatHistoryRepository chatHistory;
  final FakePeerCacheRepository peerCache;
  final FakeSettingsRepository settings;
  final FakeLocalFileRepository localFiles;
  final FakeVoicePlayer voicePlayer;

  Widget wrap(Widget child) {
    final localNode = FakeLocalNodeRepository();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: ConnectToPeer(connection)),
        RepositoryProvider.value(value: SendChatToPeer(connection)),
        RepositoryProvider.value(value: SendFileToPeer(connection)),
        RepositoryProvider.value(value: SendVoiceMessageToPeer(connection)),
        RepositoryProvider.value(
          value: ForwardMessages(
            sendChat: SendChatToPeer(connection),
            sendFile: SendFileToPeer(connection),
            sendVoice: SendVoiceMessageToPeer(connection),
            files: localFiles,
          ),
        ),
        RepositoryProvider.value(value: LoadDiscoveryName(settings)),
        RepositoryProvider.value(
          value: UpdateDiscoveryName(settings, localNode),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => PeersCubit(
              startDiscovery: StartDiscovery(discovery),
              stopDiscovery: StopDiscovery(discovery),
              refreshDiscovery: RefreshDiscovery(discovery),
              connectToPeer: ConnectToPeer(connection),
              watchPeers: WatchPeers(discovery),
              watchPeerIdentities: WatchPeerIdentities(connection),
              loadCachedPeers: LoadCachedPeers(peerCache),
              saveCachedPeers: SaveCachedPeers(peerCache),
              loadPeerDisplayNames: LoadPeerDisplayNames(peerCache),
              savePeerDisplayName: SavePeerDisplayName(peerCache),
            ),
          ),
          BlocProvider(create: (_) => VoicePlaybackCubit(voicePlayer)),
          BlocProvider(
            create: (_) => LogsCubit(watchLogs: WatchLogs(connection)),
          ),
          BlocProvider(
            create: (_) => ChatCubit(
              loadChatHistory: LoadChatHistory(chatHistory),
              saveChatHistory: SaveChatHistory(chatHistory),
            )..loadHistory(),
          ),
          BlocProvider(
            create: (_) => ReadStateCubit(
              loadLastReadTimes: LoadLastReadTimes(settings),
              saveLastRead: SaveLastRead(settings),
            )..load(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: child,
        ),
      ),
    );
  }

  /// Pumps [child]. Discovery is started afterwards (as the shell does),
  /// unless [startDiscovery] is false.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool startDiscovery = true,
  }) async {
    await tester.pumpWidget(wrap(child));
    if (startDiscovery) {
      final context = tester.element(find.byType(MaterialApp));
      unawaited(context.read<PeersCubit>().start());
    }
    // Let async cubit loads (history, last read, cached peers) finish.
    await tester.pump();
    await tester.pump();
  }
}
