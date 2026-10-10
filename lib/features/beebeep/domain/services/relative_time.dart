const List<String> _weekdays = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
String _two(int value) => value.toString().padLeft(2, '0');
String formatClock(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';
String formatDayMonth(DateTime time) =>
    '${time.day} ${_months[time.month - 1]}';

/// Whole calendar days between [time] and [now] (0 = same day).
int calendarDaysBetween(DateTime time, DateTime now) {
  final a = DateTime.utc(time.year, time.month, time.day);
  final b = DateTime.utc(now.year, now.month, now.day);
  return b.difference(a).inDays;
}

/// Chat-list time label: `HH:mm` today, `Yesterday`, weekday within the last
/// 7 days, otherwise `d MMM`. [now] is injected so the function is testable.
String relativeTimeLabel(DateTime time, {required DateTime now}) {
  final days = calendarDaysBetween(time, now);
  if (days <= 0) return formatClock(time);
  if (days == 1) return 'Yesterday';
  if (days < 7) return _weekdays[time.weekday - 1];
  return formatDayMonth(time);
}

/// `Last seen ...` text for an offline peer.
String lastSeenLabel(DateTime? lastSeen, {required DateTime now}) {
  if (lastSeen == null) return 'Offline';
  final days = calendarDaysBetween(lastSeen, now);
  if (days <= 0) return 'Last seen ${formatClock(lastSeen)}';
  if (days == 1) return 'Last seen yesterday';
  return 'Last seen ${formatDayMonth(lastSeen)}';
}
