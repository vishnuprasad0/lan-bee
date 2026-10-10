import '../entities/chat_message.dart';

import 'relative_time.dart';

/// Messages from the same side closer than this share a visual group.
const Duration messageGroupGap = Duration(minutes: 2);

const List<String> _weekdayNames = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Date separator text: `Today`, `Yesterday`, `Mon 5 Oct` (this year), or
/// `5 Oct 2025`. [now] is injected so the function is testable.
String daySeparatorLabel(DateTime day, {required DateTime now}) {
  final days = calendarDaysBetween(day, now);
  if (days == 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (day.year == now.year) {
    return '${_weekdayNames[day.weekday - 1]} ${formatDayMonth(day)}';
  }

  return '${formatDayMonth(day)} ${day.year}';
}

bool isSameDay(DateTime a, DateTime b) => calendarDaysBetween(a, b) == 0;

/// True when [current] visually continues the group that [previous] is in:
/// same side, same day, and within [messageGroupGap].
bool groupsWithPrevious(ChatMessage? previous, ChatMessage current) {
  if (previous == null) return false;
  if (previous.isOutgoing != current.isOutgoing) return false;
  if (!isSameDay(previous.timestamp, current.timestamp)) return false;
  final gap = current.timestamp.difference(previous.timestamp).abs();
  return gap <= messageGroupGap;
}

/// One row of the chat list, oldest first.
sealed class TimelineEntry {
  const TimelineEntry();
}

class DaySeparatorEntry extends TimelineEntry {
  const DaySeparatorEntry(this.day);
  final DateTime day;
}

class MessageEntry extends TimelineEntry {
  const MessageEntry({
    required this.message,
    required this.continuesPrevious,
    required this.isLastInGroup,
  });
  final ChatMessage message;

  /// Same group as the message before it (2 px gap instead of 8 px).
  final bool continuesPrevious;

  /// Only the last bubble of a group has the tail corner.
  final bool isLastInGroup;
}

/// Builds the timeline for [messages] (any order; sorted by time here):
/// a separator before the first message of each day, and grouping flags.
List<TimelineEntry> buildTimeline(List<ChatMessage> messages) {
  final sorted = [...messages]
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  final entries = <TimelineEntry>[];
  for (var i = 0; i < sorted.length; i++) {
    final message = sorted[i];
    final previous = i > 0 ? sorted[i - 1] : null;
    final next = i + 1 < sorted.length ? sorted[i + 1] : null;
    if (previous == null || !isSameDay(previous.timestamp, message.timestamp)) {
      entries.add(DaySeparatorEntry(message.timestamp));
    }
    entries.add(
      MessageEntry(
        message: message,
        continuesPrevious: groupsWithPrevious(previous, message),
        isLastInGroup: !(next != null && groupsWithPrevious(message, next)),
      ),
    );
  }

  return entries;
}
