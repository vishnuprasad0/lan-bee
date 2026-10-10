import '../entities/chat_message.dart';
import 'chat_timeline.dart';

/// Filter chips of the Files tab.
enum FileFilter { all, received, sent, voice }

/// File and voice messages of the history, both directions.
bool isFileEntry(ChatMessage message) => message.type != MessageType.text;

/// Whether [message] belongs to the list shown for [filter].
bool matchesFileFilter(ChatMessage message, FileFilter filter) {
  if (!isFileEntry(message)) return false;
  switch (filter) {
    case FileFilter.all:
      return true;
    case FileFilter.received:
      return !message.isOutgoing;
    case FileFilter.sent:
      return message.isOutgoing;
    case FileFilter.voice:
      return message.type == MessageType.voice;
  }
}

/// Files of one calendar day, newest first.
class FileDayGroup {
  const FileDayGroup({required this.day, required this.items});

  /// Any time on the day (the first item's time).
  final DateTime day;
  final List<ChatMessage> items;
}

/// Filters [history] to file and voice messages matching [filter] and groups
/// them by day, newest day and newest item first.
List<FileDayGroup> groupFileEntries(
  List<ChatMessage> history,
  FileFilter filter,
) {
  final matching = history.where((m) => matchesFileFilter(m, filter)).toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  final groups = <FileDayGroup>[];
  for (final message in matching) {
    if (groups.isNotEmpty &&
        isSameDay(groups.last.items.last.timestamp, message.timestamp)) {
      groups.last.items.add(message);
    } else {
      groups.add(FileDayGroup(day: message.timestamp, items: [message]));
    }
  }
  return groups;
}
