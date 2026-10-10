import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/services/chat_timeline.dart';

ChatMessage msg(
  String id,
  DateTime at, {
  bool outgoing = false,
  MessageType type = MessageType.text,
}) {
  return ChatMessage(
    id: id,
    peerId: 'p',
    text: id,
    timestamp: at,
    isOutgoing: outgoing,
    type: type,
  );
}

void main() {
  final now = DateTime(2026, 10, 6, 15, 0);

  group('daySeparatorLabel', () {
    test('today and yesterday', () {
      expect(daySeparatorLabel(DateTime(2026, 10, 6, 1), now: now), 'Today');
      expect(
        daySeparatorLabel(DateTime(2026, 10, 5, 23), now: now),
        'Yesterday',
      );
    });

    test('earlier this year uses weekday, day and month', () {
      // 2026-10-02 is a Friday.
      expect(daySeparatorLabel(DateTime(2026, 10, 2), now: now), 'Fri 2 Oct');
    });

    test('another year shows the year', () {
      expect(daySeparatorLabel(DateTime(2025, 10, 5), now: now), '5 Oct 2025');
    });
  });

  group('groupsWithPrevious', () {
    final base = DateTime(2026, 10, 6, 10, 0);

    test('no previous message never groups', () {
      expect(groupsWithPrevious(null, msg('a', base)), isFalse);
    });

    test('same side within 2 minutes groups, exactly 2 minutes included', () {
      final a = msg('a', base);
      expect(
        groupsWithPrevious(a, msg('b', base.add(const Duration(minutes: 1)))),
        isTrue,
      );
      expect(
        groupsWithPrevious(a, msg('b', base.add(const Duration(minutes: 2)))),
        isTrue,
      );
    });

    test('more than 2 minutes apart does not group', () {
      final a = msg('a', base);
      expect(
        groupsWithPrevious(
          a,
          msg('b', base.add(const Duration(minutes: 2, seconds: 1))),
        ),
        isFalse,
      );
    });

    test('different sides do not group', () {
      final a = msg('a', base);
      expect(
        groupsWithPrevious(
          a,
          msg('b', base.add(const Duration(seconds: 10)), outgoing: true),
        ),
        isFalse,
      );
    });

    test('messages across midnight do not group', () {
      final late = msg('a', DateTime(2026, 10, 5, 23, 59));
      final early = msg('b', DateTime(2026, 10, 6, 0, 0, 30));
      expect(groupsWithPrevious(late, early), isFalse);
    });
  });

  group('buildTimeline', () {
    test('empty list gives an empty timeline', () {
      expect(buildTimeline(const []), isEmpty);
    });

    test('adds a separator per day and groups within a day', () {
      final day1 = DateTime(2026, 10, 5, 9, 0);
      final day2 = DateTime(2026, 10, 6, 9, 0);
      final entries = buildTimeline([
        msg('c', day2.add(const Duration(minutes: 10))),
        msg('a', day1),
        msg('b', day1.add(const Duration(minutes: 1))),
        msg('d', day2.add(const Duration(minutes: 10, seconds: 30))),
      ]);

      expect(entries.map((e) => e.runtimeType.toString()).toList(), [
        'DaySeparatorEntry',
        'MessageEntry',
        'MessageEntry',
        'DaySeparatorEntry',
        'MessageEntry',
        'MessageEntry',
      ]);

      final messages = entries.whereType<MessageEntry>().toList();
      expect(messages.map((m) => m.message.id), ['a', 'b', 'c', 'd']);
      // a and b group: a is not last in its group, b has the tail.
      expect(messages[0].continuesPrevious, isFalse);
      expect(messages[0].isLastInGroup, isFalse);
      expect(messages[1].continuesPrevious, isTrue);
      expect(messages[1].isLastInGroup, isTrue);
      // c and d group on the next day.
      expect(messages[2].continuesPrevious, isFalse);
      expect(messages[2].isLastInGroup, isFalse);
      expect(messages[3].continuesPrevious, isTrue);
      expect(messages[3].isLastInGroup, isTrue);
    });

    test('a lone message has the tail and starts its own group', () {
      final entries = buildTimeline([msg('a', DateTime(2026, 10, 6, 9))]);
      final entry = entries.last as MessageEntry;
      expect(entry.continuesPrevious, isFalse);
      expect(entry.isLastInGroup, isTrue);
    });
  });
}
