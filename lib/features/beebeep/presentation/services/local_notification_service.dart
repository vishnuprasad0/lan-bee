import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/chat_message.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isForeground = true;
  int _id = 0;

  /// flutter_local_notifications 18 has no Windows implementation.
  static bool get _supported => !Platform.isWindows;

  Future<void> init() async {
    if (!_supported) return;
    final androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final iosSettings = DarwinInitializationSettings();

    // The plugin throws on macOS when macOS settings are missing.
    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  void setForeground(bool value) {
    _isForeground = value;
  }

  Future<void> showIncomingMessage({
    required String peerName,
    required ChatMessage message,
  }) async {
    if (_isForeground || !_supported) return;

    final title = peerName.isEmpty ? 'New message' : peerName;
    final body = _messageBody(message);

    final androidDetails = AndroidNotificationDetails(
      'beebeep_messages',
      'Messages',
      channelDescription: 'Chat messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: iosDetails,
    );

    await _plugin.show(_id++, title, body, details);
  }

  String _messageBody(ChatMessage message) {
    switch (message.type) {
      case MessageType.file:
        return 'File: ${message.fileName ?? 'file'}';
      case MessageType.voice:
        return 'Voice message';
      case MessageType.text:
        return message.text;
    }
  }
}
