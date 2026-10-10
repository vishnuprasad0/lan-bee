import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:beebeep/app/app_info.dart';
import 'package:beebeep/app/theme/app_theme.dart';
import 'package:beebeep/features/beebeep/data/datasources/chat_history_hive_data_source.dart';
import 'package:beebeep/features/beebeep/data/datasources/device_names_data_source.dart';
import 'package:beebeep/features/beebeep/data/datasources/peer_cache_hive_data_source.dart';
import 'package:beebeep/features/beebeep/data/datasources/settings_local_data_source.dart';
import 'package:beebeep/features/beebeep/data/models/chat_message_hive_adapter.dart';
import 'package:beebeep/features/beebeep/data/repositories/chat_history_repository_impl.dart';
import 'package:beebeep/features/beebeep/data/repositories/peer_cache_repository_impl.dart';
import 'package:beebeep/features/beebeep/data/repositories/settings_repository_impl.dart';
import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/services/display_name_suggestion.dart';
import 'package:beebeep/features/beebeep/presentation/app/app_di.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/chat/chat_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/logs/logs_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/peers/peers_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/read_state/read_state_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/voice_playback/voice_playback_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/pages/shell_page.dart';
import 'package:beebeep/features/beebeep/presentation/services/local_notification_service.dart';
import 'package:beebeep/features/beebeep/presentation/services/voice_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux) {
    // The documents directory there is the user's own Documents folder;
    // keep the database out of it.
    final support = await getApplicationSupportDirectory();
    Hive.init(support.path);
  } else {
    await Hive.initFlutter();
  }
  Hive.registerAdapter(ChatMessageAdapter());

  final settingsBox = await Hive.openBox<String>(
    SettingsLocalDataSource.boxName,
  );
  final chatHistoryBox = await Hive.openBox<ChatMessage>(
    ChatHistoryHiveDataSource.boxName,
  );
  final peerCacheBox = await Hive.openBox<dynamic>(
    PeerCacheHiveDataSource.boxName,
  );

  final settingsRepo = SettingsRepositoryImpl(
    SettingsLocalDataSource(settingsBox),
  );
  final chatHistoryRepo = ChatHistoryRepositoryImpl(
    ChatHistoryHiveDataSource(chatHistoryBox),
  );
  final peerCacheRepo = PeerCacheRepositoryImpl(
    PeerCacheHiveDataSource(peerCacheBox),
  );

  final (:displayName, :askForName) = await _resolveDisplayName(settingsRepo);

  final di = AppDi(
    displayName: displayName,
    settingsRepository: settingsRepo,
    chatHistoryRepository: chatHistoryRepo,
    peerCacheRepository: peerCacheRepo,
  );
  await di.startNode();

  runApp(BeeBeepApp(di: di, askForName: askForName));

  // After runApp: on macOS this waits for the notification permission
  // prompt, which kept the window blank until it was answered.
  unawaited(LocalNotificationService.instance.init());
}

/// The saved name, else the account or computer name (saved, so Settings
/// shows it), else the app name with [askForName] set so the shell asks.
Future<({String displayName, bool askForName})> _resolveDisplayName(
  SettingsRepositoryImpl settings,
) async {
  final saved = (await settings.getDisplayName())?.trim() ?? '';
  if (saved.isNotEmpty && saved != legacyDefaultDisplayName) {
    return (displayName: saved, askForName: false);
  }
  const device = DeviceNamesDataSource();
  final suggested = suggestDisplayName(
    userName: device.userName(),
    hostName: device.hostName(),
  );
  if (suggested == null) {
    return (displayName: AppInfo.name, askForName: true);
  }
  await settings.setDisplayName(suggested);
  return (displayName: suggested, askForName: false);
}

class BeeBeepApp extends StatefulWidget {
  const BeeBeepApp({super.key, required this.di, this.askForName = false});

  final AppDi di;

  /// No name could be found on this device; the shell asks for one.
  final bool askForName;

  @override
  State<BeeBeepApp> createState() => _BeeBeepAppState();
}

class _BeeBeepAppState extends State<BeeBeepApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    LocalNotificationService.instance.setForeground(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.di.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    LocalNotificationService.instance.setForeground(isForeground);
    if (isForeground) {
      unawaited(widget.di.ensureOnline());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.di.connectToPeer),
        RepositoryProvider.value(value: widget.di.sendChatToPeer),
        RepositoryProvider.value(value: widget.di.sendFileToPeer),
        RepositoryProvider.value(value: widget.di.sendVoiceMessageToPeer),
        RepositoryProvider.value(value: widget.di.forwardMessages),
        RepositoryProvider.value(value: widget.di.loadDiscoveryName),
        RepositoryProvider.value(value: widget.di.updateDiscoveryName),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => PeersCubit(
              startDiscovery: widget.di.startDiscovery,
              stopDiscovery: widget.di.stopDiscovery,
              refreshDiscovery: widget.di.refreshDiscovery,
              connectToPeer: widget.di.connectToPeer,
              watchPeers: widget.di.watchPeers,
              watchPeerIdentities: widget.di.watchPeerIdentities,
              loadCachedPeers: widget.di.loadCachedPeers,
              saveCachedPeers: widget.di.saveCachedPeers,
              loadPeerDisplayNames: widget.di.loadPeerDisplayNames,
              savePeerDisplayName: widget.di.savePeerDisplayName,
            ),
          ),
          BlocProvider(create: (_) => VoicePlaybackCubit(AudioVoicePlayer())),
          BlocProvider(
            create: (_) => LogsCubit(watchLogs: widget.di.watchLogs),
          ),
          BlocProvider(
            create: (_) {
              final cubit = ReadStateCubit(
                loadLastReadTimes: widget.di.loadLastReadTimes,
                saveLastRead: widget.di.saveLastRead,
              );
              unawaited(cubit.load());
              return cubit;
            },
          ),
          BlocProvider(
            create: (context) {
              final cubit = ChatCubit(
                loadChatHistory: widget.di.loadChatHistory,
                saveChatHistory: widget.di.saveChatHistory,
              );
              unawaited(cubit.loadHistory());
              // Listen to received messages and add them to chat
              widget.di.watchReceivedMessages().listen((receivedMsg) {
                final message = ChatMessage(
                  id: receivedMsg.messageId,
                  peerId: receivedMsg.peerId,
                  text: receivedMsg.text,
                  timestamp: receivedMsg.timestamp,
                  isOutgoing: false,
                  status: MessageStatus.delivered,
                  type: receivedMsg.type,
                  filePath: receivedMsg.filePath,
                  fileSize: receivedMsg.fileSize,
                  fileName: receivedMsg.fileName,
                  duration: receivedMsg.duration,
                );
                cubit.addMessage(message);
                unawaited(
                  LocalNotificationService.instance.showIncomingMessage(
                    peerName: receivedMsg.peerName,
                    message: message,
                  ),
                );
              });
              return cubit;
            },
          ),
        ],
        child: MaterialApp(
          title: AppInfo.name,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: ShellPage(askForName: widget.askForName),
        ),
      ),
    );
  }
}
