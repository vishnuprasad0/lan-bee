import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/presentation/pages/files_tab.dart';

import '../../../support/test_harness.dart';

const anil = Peer(
  id: 'anil-id',
  displayName: 'Anil',
  host: '10.0.0.2',
  port: 6475,
);

ChatMessage fileMsg(
  String id,
  String name,
  DateTime at, {
  bool outgoing = false,
  MessageType type = MessageType.file,
}) {
  return ChatMessage(
    id: id,
    peerId: anil.id,
    text: name,
    timestamp: at,
    isOutgoing: outgoing,
    type: type,
    fileName: name,
    fileSize: 2048,
    filePath: '/missing/$name',
    duration: type == MessageType.voice ? const Duration(seconds: 7) : null,
  );
}

void main() {
  testWidgets('Files tab empty state', (tester) async {
    final harness = TestHarness(
      messages: [
        ChatMessage(
          id: 't',
          peerId: anil.id,
          text: 'only text',
          timestamp: DateTime(2026, 10, 6),
          isOutgoing: false,
        ),
      ],
    );
    await harness.pump(tester, const Scaffold(body: FilesTab()));

    expect(find.text('Files you send or receive appear here.'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('filter chips switch the lists', (tester) async {
    final day = DateTime(2026, 10, 5, 9);
    final harness = TestHarness(
      onlinePeers: const [anil],
      messages: [
        fileMsg('1', 'inbox.pdf', day),
        fileMsg(
          '2',
          'outbox.zip',
          day.add(const Duration(hours: 1)),
          outgoing: true,
        ),
        fileMsg(
          '3',
          'voice_1.aac',
          day.add(const Duration(hours: 2)),
          type: MessageType.voice,
        ),
      ],
    );
    await harness.pump(tester, const Scaffold(body: FilesTab()));

    // All: every row, with the peer name and the missing-file note.
    expect(find.text('inbox.pdf'), findsOneWidget);
    expect(find.text('outbox.zip'), findsOneWidget);
    expect(find.text('Voice message'), findsOneWidget);
    expect(find.textContaining('From Anil'), findsNWidgets(2));
    expect(find.textContaining('To Anil'), findsOneWidget);
    expect(find.textContaining('Not on this device'), findsNWidgets(3));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Received'));
    await tester.pump();
    expect(find.text('inbox.pdf'), findsOneWidget);
    expect(find.text('Voice message'), findsOneWidget);
    expect(find.text('outbox.zip'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sent'));
    await tester.pump();
    expect(find.text('outbox.zip'), findsOneWidget);
    expect(find.text('inbox.pdf'), findsNothing);
    expect(find.text('Voice message'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Voice'));
    await tester.pump();
    expect(find.text('Voice message'), findsOneWidget);
    expect(find.text('inbox.pdf'), findsNothing);
    expect(find.text('outbox.zip'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
    await tester.pump();
    expect(find.text('inbox.pdf'), findsOneWidget);
  });

  testWidgets('a filter with no matches explains itself', (tester) async {
    final harness = TestHarness(
      messages: [fileMsg('1', 'inbox.pdf', DateTime(2026, 10, 5, 9))],
    );
    await harness.pump(tester, const Scaffold(body: FilesTab()));

    await tester.tap(find.widgetWithText(ChoiceChip, 'Sent'));
    await tester.pump();
    expect(find.text('No files match this filter.'), findsOneWidget);
  });

  testWidgets('rows are grouped under date headings', (tester) async {
    final harness = TestHarness(
      messages: [
        fileMsg('1', 'old.pdf', DateTime(2025, 1, 2, 9)),
        fileMsg('2', 'older.pdf', DateTime(2025, 1, 3, 9)),
      ],
    );
    await harness.pump(tester, const Scaffold(body: FilesTab()));

    expect(find.text('2 Jan 2025'), findsOneWidget);
    expect(find.text('3 Jan 2025'), findsOneWidget);
    // Newest day first.
    expect(
      tester.getTopLeft(find.text('3 Jan 2025')).dy,
      lessThan(tester.getTopLeft(find.text('2 Jan 2025')).dy),
    );
  });
}
