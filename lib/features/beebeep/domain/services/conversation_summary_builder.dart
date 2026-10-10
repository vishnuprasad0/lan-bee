import '../entities/chat_message.dart';
import '../entities/conversation_summary.dart';
import '../entities/peer.dart';

/// Builds the Chats tab rows from raw messages, known peers, and the
/// last-read time per peer. Pure Dart so it can be unit-tested.
class ConversationSummaryBuilder {
  const ConversationSummaryBuilder();
  static const String youPrefix = 'You: ';
  static const String unknownName = 'Unknown';
  List<ConversationSummary> build({
    required List<ChatMessage> messages,
    required List<Peer> peers,
    required Set<String> onlinePeerIds,
    required Map<String, DateTime> lastRead,
  }) {
    final byPeer = <String, List<ChatMessage>>{};
    for (final message in messages) {
      byPeer.putIfAbsent(message.peerId, () => <ChatMessage>[]).add(message);
    }
    final peersById = <String, Peer>{for (final p in peers) p.id: p};
    final summaries = <ConversationSummary>[];
    for (final entry in byPeer.entries) {
      final peerMessages = entry.value;
      var last = peerMessages.first;
      for (final message in peerMessages) {
        if (!message.timestamp.isBefore(last.timestamp)) last = message;
      }
      final readAt = lastRead[entry.key];
      final unread = peerMessages.where((m) {
        if (m.isOutgoing) return false;
        return readAt == null || m.timestamp.isAfter(readAt);
      }).length;
      final name = peersById[entry.key]?.displayName.trim() ?? '';
      summaries.add(
        ConversationSummary(
          peerId: entry.key,
          displayName: name.isEmpty ? unknownName : name,
          isOnline: onlinePeerIds.contains(entry.key),
          preview: previewFor(last),
          previewType: last.type,
          lastMessageTime: last.timestamp,
          unreadCount: unread,
          lastMessageOutgoing: last.isOutgoing,
        ),
      );
    }
    summaries.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    return summaries;
  }

  /// Preview text for one message: `You: ` prefix for outgoing, file name for
  /// files, `Voice message m:ss` for voice, leading `> ` quote lines removed.
  String previewFor(ChatMessage message) {
    final String body;
    switch (message.type) {
      case MessageType.file:
        final name = message.fileName?.trim() ?? '';
        body = name.isEmpty ? 'File' : name;
      case MessageType.voice:
        final duration = message.duration;
        body = duration == null
            ? 'Voice message'
            : 'Voice message ${formatDuration(duration)}';
      case MessageType.text:
        body = stripQuote(message.text);
    }
    return message.isOutgoing ? '$youPrefix$body' : body;
  }

  /// Removes leading `> ` quote lines and collapses the rest to one line.
  /// A message that is only a quote falls back to the quoted text.
  static String stripQuote(String text) {
    final lines = text.split('\n');
    var index = 0;
    while (index < lines.length && lines[index].startsWith('> ')) {
      index++;
    }
    final rest = lines.sublist(index).join(' ').trim();
    if (rest.isNotEmpty || index == 0) {
      return rest.replaceAll(RegExp(r'\s+'), ' ');
    }
    final quoted = lines
        .sublist(0, index)
        .map((l) => l.substring(2))
        .join(' ')
        .trim();
    return quoted.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
