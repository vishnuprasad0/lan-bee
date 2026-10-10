import 'package:flutter_test/flutter_test.dart';
import 'package:beebeep/features/beebeep/domain/services/relative_time.dart';

void main() {
  // Wednesday 7 October 2026, 15:30.
  final now = DateTime(2026, 10, 7, 15, 30);
  group('relativeTimeLabel', () {
    test('same day shows HH:mm with zero padding', () {
      expect(relativeTimeLabel(DateTime(2026, 10, 7, 9, 5), now: now), '09:05');
      expect(relativeTimeLabel(DateTime(2026, 10, 7, 0, 0), now: now), '00:00');
    });
    test('previous calendar day shows Yesterday even under 24 hours', () {
      final lateLastNight = DateTime(2026, 10, 6, 23, 59);
      expect(relativeTimeLabel(lateLastNight, now: now), 'Yesterday');
    });
    test('2 to 6 days ago shows the weekday', () {
      expect(relativeTimeLabel(DateTime(2026, 10, 5, 8), now: now), 'Mon');
      expect(relativeTimeLabel(DateTime(2026, 10, 1, 8), now: now), 'Thu');
    });
    test('7 or more days ago shows d MMM', () {
      expect(relativeTimeLabel(DateTime(2026, 9, 30, 8), now: now), '30 Sep');
      expect(relativeTimeLabel(DateTime(2026, 1, 3, 8), now: now), '3 Jan');
    });
    test('a future timestamp is treated as today', () {
      expect(relativeTimeLabel(DateTime(2026, 10, 8, 1, 2), now: now), '01:02');
    });
  });
  group('lastSeenLabel', () {
    test('null means Offline', () {
      expect(lastSeenLabel(null, now: now), 'Offline');
    });
    test('today, yesterday, older', () {
      expect(
        lastSeenLabel(DateTime(2026, 10, 7, 10, 42), now: now),
        'Last seen 10:42',
      );
      expect(
        lastSeenLabel(DateTime(2026, 10, 6, 10, 42), now: now),
        'Last seen yesterday',
      );
      expect(
        lastSeenLabel(DateTime(2026, 10, 1, 10, 42), now: now),
        'Last seen 1 Oct',
      );
    });
  });
}
