import 'dart:typed_data';

import '../entities/chat_message.dart';
import '../entities/peer.dart';
import '../repositories/local_file_repository.dart';

import 'send_chat_to_peer.dart';
import 'send_file_to_peer.dart';
import 'send_voice_message_to_peer.dart';

/// Outcome of forwarding.
class ForwardResult {
  const ForwardResult({
    required this.sent,
    required this.forwardedCount,
    required this.skippedCount,
    required this.chatCount,
  });

  /// New outgoing messages to add to the target chats (failed ones included,
  /// marked `failed`).
  final List<ChatMessage> sent;

  /// Number of messages sent successfully (messages x peers).
  final int forwardedCount;

  /// Distinct source messages not sent because the local file is gone.
  final int skippedCount;

  /// Number of target chats that received at least one message.
  final int chatCount;
}

/// Re-sends messages as new outgoing messages to other peers.
class ForwardMessages {
  ForwardMessages({
    required SendChatToPeer sendChat,
    required SendFileToPeer sendFile,
    required SendVoiceMessageToPeer sendVoice,
    required LocalFileRepository files,
    DateTime Function()? now,
  }) : _sendChat = sendChat,
       _sendFile = sendFile,
       _sendVoice = sendVoice,
       _files = files,
       _now = now ?? DateTime.now;
  final SendChatToPeer _sendChat;
  final SendFileToPeer _sendFile;
  final SendVoiceMessageToPeer _sendVoice;
  final LocalFileRepository _files;
  final DateTime Function() _now;
  int _counter = 0;

  Future<ForwardResult> call({
    required List<ChatMessage> messages,
    required List<Peer> targets,
  }) async {
    final ordered = [...messages]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final sent = <ChatMessage>[];
    final skipped = <String>{};
    final reached = <String>{};
    var succeeded = 0;
    for (final message in ordered) {
      Uint8List? bytes;
      if (message.type != MessageType.text) {
        final path = message.filePath;
        bytes = path == null ? null : await _files.readBytes(path);
        if (bytes == null) {
          skipped.add(message.id);
          continue;
        }
      }
      for (final peer in targets) {
        var status = MessageStatus.sent;
        try {
          await _sendOne(peer, message, bytes);
          succeeded++;
          reached.add(peer.id);
        } on Object {
          status = MessageStatus.failed;
        }
        sent.add(_copyFor(peer, message, status));
      }
    }
    return ForwardResult(
      sent: sent,
      forwardedCount: succeeded,
      skippedCount: skipped.length,
      chatCount: reached.length,
    );
  }

  Future<void> _sendOne(Peer peer, ChatMessage message, Uint8List? bytes) {
    switch (message.type) {
      case MessageType.text:
        return _sendChat(peer: peer, text: message.text);
      case MessageType.file:
        return _sendFile(
          peer: peer,
          fileName: message.fileName ?? 'file',
          bytes: bytes!,
          fileSize: bytes.length,
        );
      case MessageType.voice:
        return _sendVoice(
          peer: peer,
          fileName: message.fileName ?? 'voice.aac',
          bytes: bytes!,
          fileSize: bytes.length,
          duration: message.duration,
        );
    }
  }

  ChatMessage _copyFor(Peer peer, ChatMessage source, MessageStatus status) {
    _counter++;

    // Strictly increasing so forwarded messages keep their order.
    final now = _now().add(Duration(microseconds: _counter));
    return ChatMessage(
      id: '${now.microsecondsSinceEpoch}-fwd$_counter',
      peerId: peer.id,
      text: source.text,
      timestamp: now,
      isOutgoing: true,
      status: status,
      type: source.type,
      filePath: source.filePath,
      fileSize: source.fileSize,
      fileName: source.fileName,
      duration: source.duration,
    );
  }
}
