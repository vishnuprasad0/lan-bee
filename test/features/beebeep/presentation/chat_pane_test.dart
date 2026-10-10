import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/presentation/pages/chat_page.dart';
import 'package:beebeep/features/beebeep/presentation/pages/chats_tab.dart';
import 'package:beebeep/features/beebeep/presentation/widgets/common/chat_pane_scope.dart';

import '../../../support/test_harness.dart';

void main() {
  const peer = Peer(
    id: 'anil-id',
    displayName: 'Anil',
    host: '10.0.0.2',
    port: 6475,
  );

  TestHarness harnessWithChat() => TestHarness(
    onlinePeers: const [peer],
    messages: [
      ChatMessage(
        id: '1',
        peerId: 'anil-id',
        text: 'Hello',
        timestamp: DateTime.now(),
        isOutgoing: false,
      ),
    ],
  );

  testWidgets('In the wide layout a chat opens in the pane, not a new page', (
    tester,
  ) async {
    Peer? opened;
    await harnessWithChat().pump(
      tester,
      Scaffold(
        body: ChatPaneScope(
          openPeerId: null,
          onOpen: (p) => opened = p,
          child: ChatsTab(onGoToUsers: () {}),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Anil'));
    await tester.pumpAndSettle();

    expect(opened?.id, 'anil-id');
    expect(find.byType(ChatPage), findsNothing);
  });

  testWidgets('Without the pane a chat opens on its own page', (tester) async {
    await harnessWithChat().pump(
      tester,
      Scaffold(body: ChatsTab(onGoToUsers: () {})),
    );
    await tester.pump();

    await tester.tap(find.text('Anil'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatPage), findsOneWidget);
  });
}
