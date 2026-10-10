import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/cached_peer.dart';
import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/presentation/pages/chats_tab.dart';

import '../../../support/test_harness.dart';

void main() {
  testWidgets('Chats tab empty state offers a way to Users', (tester) async {
    final harness = TestHarness();
    var wentToUsers = false;

    await harness.pump(
      tester,
      Scaffold(body: ChatsTab(onGoToUsers: () => wentToUsers = true)),
    );

    expect(find.text('No chats yet'), findsOneWidget);
    expect(
      find.text('People on the same Wi-Fi show up in Users.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Go to Users'));
    expect(wentToUsers, isTrue);
  });

  testWidgets('Chats tab shows name, preview, and unread badge', (
    tester,
  ) async {
    const peer = Peer(
      id: 'anil-id',
      displayName: 'Anil',
      host: '10.0.0.2',
      port: 6475,
    );
    final now = DateTime.now();
    final harness = TestHarness(
      onlinePeers: const [peer],
      messages: [
        ChatMessage(
          id: '1',
          peerId: 'anil-id',
          text: 'older',
          timestamp: now.subtract(const Duration(minutes: 10)),
          isOutgoing: false,
        ),
        ChatMessage(
          id: '2',
          peerId: 'anil-id',
          text: '> quoted\nSee you at lunch',
          timestamp: now.subtract(const Duration(minutes: 5)),
          isOutgoing: false,
        ),
      ],
      lastRead: {'anil-id': now.subtract(const Duration(minutes: 7))},
    );

    await harness.pump(tester, Scaffold(body: ChatsTab(onGoToUsers: () {})));
    await tester.pump();

    expect(find.text('Anil'), findsOneWidget);
    expect(find.text('See you at lunch'), findsOneWidget);
    // One incoming message is newer than lastRead.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('No chats yet'), findsNothing);
  });

  testWidgets('Chats tab shows a conversation with a cached offline peer', (
    tester,
  ) async {
    final now = DateTime.now();
    final harness = TestHarness(
      cachedPeers: {
        'maya-id': CachedPeer(
          peerId: 'maya-id',
          displayName: 'Maya',
          host: '10.0.0.3',
          port: 6475,
          lastSeen: now.subtract(const Duration(hours: 1)),
        ),
      },
      messages: [
        ChatMessage(
          id: '1',
          peerId: 'maya-id',
          text: 'sent',
          timestamp: now.subtract(const Duration(minutes: 1)),
          isOutgoing: true,
        ),
      ],
    );

    await harness.pump(tester, Scaffold(body: ChatsTab(onGoToUsers: () {})));
    await tester.pump();

    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('You: sent'), findsOneWidget);
  });
}
