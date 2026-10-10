import 'package:equatable/equatable.dart';
import 'chat_message.dart';

/// One row of the Chats tab: a peer, its last message, and its unread count.
class ConversationSummary extends Equatable {
  const ConversationSummary({
    required this.peerId,
    required this.displayName,
    required this.isOnline,
    required this.preview,
    required this.previewType,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.lastMessageOutgoing,
  });
  final String peerId;
  final String displayName;
  final bool isOnline;

  /// Single-line preview, already prefixed with `You: ` for outgoing messages.
  final String preview;

  /// Lets the UI choose a leading icon (file, mic) for [preview].
  final MessageType previewType;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool lastMessageOutgoing;
  bool get hasUnread => unreadCount > 0;
  @override
  List<Object?> get props => [
    peerId,
    displayName,
    isOnline,
    preview,
    previewType,
    lastMessageTime,
    unreadCount,
    lastMessageOutgoing,
  ];
}
