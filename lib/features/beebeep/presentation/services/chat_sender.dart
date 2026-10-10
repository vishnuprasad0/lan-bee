import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/peer.dart';
import '../../domain/use_cases/send_chat_to_peer.dart';
import '../../domain/use_cases/send_file_to_peer.dart';
import '../../domain/use_cases/send_voice_message_to_peer.dart';
import '../bloc/chat/chat_cubit.dart';

/// Sends to one peer and records the outgoing message in [ChatCubit]. The
/// message is added as `sending`, then becomes `sent` or `failed`.
class ChatSender {
  ChatSender({
    required SendChatToPeer sendChat,
    required SendFileToPeer sendFile,
    required SendVoiceMessageToPeer sendVoice,
    required ChatCubit chat,
    DateTime Function()? now,
  }) : _sendChat = sendChat,
       _sendFile = sendFile,
       _sendVoice = sendVoice,
       _chat = chat,
       _now = now ?? DateTime.now;
  final SendChatToPeer _sendChat;
  final SendFileToPeer _sendFile;
  final SendVoiceMessageToPeer _sendVoice;
  final ChatCubit _chat;
  final DateTime Function() _now;
  int _counter = 0;
  String _nextId() {
    _counter++;
    return '${_now().microsecondsSinceEpoch}-$_counter';
  }

  Future<void> sendText(Peer peer, String text) {
    final message = ChatMessage(
      id: _nextId(),
      peerId: peer.id,
      text: text,
      timestamp: _now(),
      isOutgoing: true,
      status: MessageStatus.sending,
    );
    return _track(message, () => _sendChat(peer: peer, text: text));
  }

  Future<void> sendFile(
    Peer peer, {
    required String name,
    required Uint8List bytes,
    required int size,
    String? path,
  }) {
    final message = ChatMessage(
      id: _nextId(),
      peerId: peer.id,
      text: name,
      timestamp: _now(),
      isOutgoing: true,
      status: MessageStatus.sending,
      type: MessageType.file,
      fileName: name,
      fileSize: size,
      filePath: path,
    );
    return _track(
      message,
      () => _sendFile(peer: peer, fileName: name, bytes: bytes, fileSize: size),
    );
  }

  Future<void> sendVoice(
    Peer peer, {
    required String name,
    required Uint8List bytes,
    required String path,
    Duration? duration,
  }) {
    final message = ChatMessage(
      id: _nextId(),
      peerId: peer.id,
      text: 'Voice message',
      timestamp: _now(),
      isOutgoing: true,
      status: MessageStatus.sending,
      type: MessageType.voice,
      fileName: name,
      fileSize: bytes.length,
      filePath: path,
      duration: duration,
    );
    return _track(
      message,
      () => _sendVoice(
        peer: peer,
        fileName: name,
        bytes: bytes,
        fileSize: bytes.length,
        duration: duration,
      ),
    );
  }

  Future<void> _track(ChatMessage message, Future<void> Function() send) async {
    _chat.addMessage(message);
    try {
      await send();
      _chat.updateMessage(
        message.id,
        message.copyWith(status: MessageStatus.sent),
      );
    } on Object catch (error) {
      debugPrint('Send failed: $error');
      _chat.updateMessage(
        message.id,
        message.copyWith(status: MessageStatus.failed),
      );
    }
  }
}
