import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/services/file_entries.dart';

ChatMessage msg(
  String id,
  DateTime at, {
  bool outgoing = false,
  MessageType type = MessageType.file,
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
  final day1 = DateTime(2026, 10, 5, 9);
  final day2 = DateTime(2026, 10, 6, 9);
  final history = [
    msg('text', day2, type: MessageType.text),
    msg('recv-file', day1),
    msg('sent-file', day1.add(const Duration(hours: 1)), outgoing: true),
    msg('recv-voice', day2, type: MessageType.voice),
    msg(
      'sent-voice',
      day2.add(const Duration(hours: 2)),
      outgoing: true,
      type: MessageType.voice,
    ),
  ];

  List<String> ids(FileFilter filter) => [
    for (final g in groupFileEntries(history, filter))
      for (final m in g.items) m.id,
  ];

  test('All has files and voice in both directions, newest first, no text', () {
    expect(ids(FileFilter.all), [
      'sent-voice',
      'recv-voice',
      'sent-file',
      'recv-file',
    ]);
  });

  test('Received keeps only incoming files and voice', () {
    expect(ids(FileFilter.received), ['recv-voice', 'recv-file']);
  });

  test('Sent keeps only outgoing files and voice', () {
    expect(ids(FileFilter.sent), ['sent-voice', 'sent-file']);
  });

  test('Voice keeps voice notes from both sides', () {
    expect(ids(FileFilter.voice), ['sent-voice', 'recv-voice']);
  });

  test('items are grouped by day, newest day first', () {
    final groups = groupFileEntries(history, FileFilter.all);
    expect(groups.length, 2);
    expect(groups[0].items.map((m) => m.id), ['sent-voice', 'recv-voice']);
    expect(groups[0].day.day, 6);
    expect(groups[1].items.map((m) => m.id), ['sent-file', 'recv-file']);
    expect(groups[1].day.day, 5);
  });

  test('empty history and text-only history give no groups', () {
    expect(groupFileEntries(const [], FileFilter.all), isEmpty);
    expect(
      groupFileEntries([
        msg('t', day1, type: MessageType.text),
      ], FileFilter.all),
      isEmpty,
    );
  });
}
