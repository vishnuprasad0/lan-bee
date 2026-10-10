import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/forward_messages.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/chat/chat_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/pages/forward_picker_page.dart';

import '../../../support/test_harness.dart';

const anil = Peer(id: 'a', displayName: 'Anil', host: '10.0.0.2', port: 1);
const bina = Peer(id: 'b', displayName: 'Bina', host: '10.0.0.3', port: 1);

void main() {
  testWidgets('forward picker sends to the chosen peers and reports back', (
    tester,
  ) async {
    final source = ChatMessage(
      id: 'm1',
      peerId: 'src',
      text: 'see this',
      timestamp: DateTime(2026, 10, 6, 9),
      isOutgoing: false,
    );
    final harness = TestHarness(onlinePeers: const [bina, anil]);
    ForwardResult? result;

    await harness.pump(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<ForwardResult>(
                MaterialPageRoute(
                  builder: (_) => ForwardPickerPage(messages: [source]),
                ),
              );
            },
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    // Send is disabled until someone is chosen.
    expect(find.text('Send'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.bySubtype<FilledButton>()).onPressed,
      isNull,
    );

    // Online peers are listed, sorted by name.
    final names = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .map((t) => (t.title! as Text).data)
        .toList();
    expect(names, ['Anil', 'Bina']);

    // Search filters the list.
    await tester.enterText(find.byType(TextField), 'bin');
    await tester.pump();
    expect(find.text('Anil'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    await tester.tap(find.text('Anil'));
    await tester.tap(find.text('Bina'));
    await tester.pump();
    expect(find.text('Send (2)'), findsOneWidget);

    await tester.tap(find.text('Send (2)'));
    await tester.pumpAndSettle();

    expect(harness.connection.sentChats, [
      ('a', 'see this'),
      ('b', 'see this'),
    ]);
    expect(result?.chatCount, 2);
    expect(result?.forwardedCount, 2);

    final context = tester.element(find.byType(Scaffold));
    final chat = context.read<ChatCubit>();
    expect(chat.getMessagesForPeer('a').single.isOutgoing, isTrue);
    expect(chat.getMessagesForPeer('b').single.text, 'see this');
  });
}
