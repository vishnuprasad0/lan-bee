import '../entities/chat_message.dart';

import 'relative_time.dart';

/// True for messages that carry copyable text.
bool isCopyable(ChatMessage message) => message.type == MessageType.text;

/// Text for the clipboard. One message: its text. Several: one line per text
/// message in time order, `[d MMM HH:mm] Name: text`. [nameFor] gives the
/// author name (for example "You" for outgoing messages).
String formatMessagesForCopy(
  List<ChatMessage> messages, {
  required String Function(ChatMessage message) nameFor,
}) {
  final texts = messages.where(isCopyable).toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  if (texts.length == 1 && messages.length == 1) return texts.single.text;
  return texts
      .map((m) {
        final stamp =
            '${formatDayMonth(m.timestamp)} '
            '${formatClock(m.timestamp)}';
        return '[$stamp] ${nameFor(m)}: ${m.text}';
      })
      .join('\n');
}
