import '../../../domain/entities/conversation_summary.dart';
import '../../../domain/services/conversation_summary_builder.dart';
import '../chat/chat_state.dart';
import '../peers/peers_state.dart';
import '../read_state/read_state.dart';

const ConversationSummaryBuilder _builder = ConversationSummaryBuilder();

/// Chats tab rows derived from the three cubit states. Used by the Chats tab
/// and by the shell for the unread badge, so both always agree.
List<ConversationSummary> conversationSummariesOf({
  required PeersState peers,
  required ChatState chat,
  required ReadState read,
}) {
  return _builder.build(
    messages: chat.messages,
    peers: [for (final p in peers.peers) p.peer],
    onlinePeerIds: {
      for (final p in peers.peers)
        if (p.isOnline) p.peer.id,
    },
    lastRead: read.lastRead,
  );
}

int totalUnread(List<ConversationSummary> summaries) {
  return summaries.fold<int>(0, (sum, s) => sum + s.unreadCount);
}
