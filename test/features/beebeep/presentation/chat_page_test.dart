import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/presentation/bloc/chat/chat_cubit.dart';
import 'package:beebeep/features/beebeep/presentation/pages/chat_page.dart';

import '../../../support/test_harness.dart';

const anil = Peer(
  id: 'anil-id',
  displayName: 'Anil',
  host: '10.0.0.2',
  port: 6475,
);

ChatMessage text(String id, String body, DateTime at, {bool outgoing = false}) {
  return ChatMessage(
    id: id,
    peerId: anil.id,
    text: body,
    timestamp: at,
    isOutgoing: outgoing,
  );
}

ChatMessage fileMessage(String id, DateTime at, {String? path}) {
  return ChatMessage(
    id: id,
    peerId: anil.id,
    text: 'report.pdf',
    timestamp: at,
    isOutgoing: false,
    type: MessageType.file,
    fileName: 'report.pdf',
    fileSize: 2048,
    filePath: path,
  );
}

Future<TestHarness> openChat(
  WidgetTester tester,
  List<ChatMessage> messages,
) async {
  final harness = TestHarness(onlinePeers: const [anil], messages: messages);
  await harness.pump(tester, const ChatPage(peer: anil));
  return harness;
}

Future<void> openOverflow(WidgetTester tester) async {
  await tester.tap(find.byTooltip('More actions'));
  await tester.pumpAndSettle();
}

/// Mocks the platform channel, records calls, and returns the log.
List<MethodCall> mockPlatform() {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  return calls;
}

void main() {
  final t0 = DateTime(2026, 10, 6, 9, 5);

  group('chat screen', () {
    testWidgets('shows name, status, messages, and quote cards', (
      tester,
    ) async {
      await openChat(tester, [
        text('1', 'Hello', t0),
        text(
          '2',
          '> earlier words\nmy answer',
          t0.add(const Duration(hours: 1)),
        ),
      ]);

      expect(find.text('Anil'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('earlier words'), findsOneWidget);
      expect(find.text('my answer'), findsOneWidget);
      expect(find.textContaining('> '), findsNothing);
    });

    testWidgets('offline peer shows the banner', (tester) async {
      final harness = TestHarness(messages: [text('1', 'Hello', t0)]);
      await harness.pump(tester, const ChatPage(peer: anil));
      expect(
        find.text('Anil is offline. Messages will fail until they are back.'),
        findsOneWidget,
      );
    });

    testWidgets('empty chat shows an empty state', (tester) async {
      await openChat(tester, const []);
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('missing file is greyed with a note', (tester) async {
      await openChat(tester, [fileMessage('f', t0)]);
      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.text('File no longer on this device'), findsOneWidget);
    });
  });

  group('selection mode', () {
    testWidgets('long press selects, tap toggles, close exits', (tester) async {
      mockPlatform();
      await openChat(tester, [
        text('1', 'Hello', t0),
        text('2', 'World', t0.add(const Duration(hours: 1))),
      ]);

      await tester.longPress(find.text('Hello'));
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('World'));
      await tester.pump();
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.text('World'));
      await tester.pump();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Cancel selection'));
      await tester.pump();
      expect(find.text('1 selected'), findsNothing);
      expect(find.text('Anil'), findsOneWidget);
    });

    testWidgets('one text message offers Reply, Copy, Forward, Info, Delete', (
      tester,
    ) async {
      mockPlatform();
      await openChat(tester, [text('1', 'Hello', t0)]);

      await tester.longPress(find.text('Hello'));
      await tester.pump();

      expect(find.byTooltip('Reply'), findsOneWidget);
      expect(find.byTooltip('Copy'), findsOneWidget);
      expect(find.byTooltip('Forward'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      await openOverflow(tester);
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('one file message offers file actions but no Copy', (
      tester,
    ) async {
      mockPlatform();
      final dir = Directory.systemTemp.createTempSync('lanbee_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/report.pdf')..writeAsBytesSync([1, 2, 3]);
      await openChat(tester, [fileMessage('f', t0, path: file.path)]);

      await tester.longPress(find.text('report.pdf'));
      await tester.pump();

      expect(find.byTooltip('Reply'), findsOneWidget);
      expect(find.byTooltip('Forward'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      expect(find.byTooltip('Copy'), findsNothing);
      await openOverflow(tester);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
    });

    testWidgets('two messages offer only Copy, Forward, Delete', (
      tester,
    ) async {
      mockPlatform();
      await openChat(tester, [
        text('1', 'Hello', t0),
        text('2', 'World', t0.add(const Duration(hours: 1))),
      ]);

      await tester.longPress(find.text('Hello'));
      await tester.pump();
      await tester.tap(find.text('World'));
      await tester.pump();

      expect(find.byTooltip('Copy'), findsOneWidget);
      expect(find.byTooltip('Forward'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      expect(find.byTooltip('Reply'), findsNothing);
      expect(find.byTooltip('More actions'), findsNothing);
    });

    testWidgets('Copy puts one message text on the clipboard', (tester) async {
      final calls = mockPlatform();
      await openChat(tester, [text('1', 'Hello', t0)]);

      await tester.longPress(find.text('Hello'));
      await tester.pump();
      await tester.tap(find.byTooltip('Copy'));
      await tester.pump();

      final copy = calls.lastWhere((c) => c.method == 'Clipboard.setData');
      expect((copy.arguments as Map)['text'], 'Hello');
      expect(find.text('Copied'), findsOneWidget);
      expect(find.text('1 selected'), findsNothing);
    });

    testWidgets('Copy formats several messages in time order', (tester) async {
      final calls = mockPlatform();
      await openChat(tester, [
        text('2', 'Fine', t0.add(const Duration(minutes: 3)), outgoing: true),
        text('1', 'Hello', t0),
      ]);

      await tester.longPress(find.text('Hello'));
      await tester.pump();
      await tester.tap(find.text('Fine'));
      await tester.pump();
      await tester.tap(find.byTooltip('Copy'));
      await tester.pump();

      final copy = calls.lastWhere((c) => c.method == 'Clipboard.setData');
      expect(
        (copy.arguments as Map)['text'],
        '[6 Oct 09:05] Anil: Hello\n[6 Oct 09:08] You: Fine',
      );
    });

    testWidgets('Delete asks first and then removes the messages', (
      tester,
    ) async {
      mockPlatform();
      final harness = await openChat(tester, [
        text('1', 'Hello', t0),
        text('2', 'World', t0.add(const Duration(hours: 1))),
        text('3', 'Keep me', t0.add(const Duration(hours: 2))),
      ]);

      await tester.longPress(find.text('Hello'));
      await tester.pump();
      await tester.tap(find.text('World'));
      await tester.pump();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete 2 messages for you?'), findsOneWidget);
      expect(find.text('They stay on the other device.'), findsOneWidget);

      // Cancel keeps everything.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Hello'), findsOneWidget);
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsNothing);
      expect(find.text('World'), findsNothing);
      expect(find.text('Keep me'), findsOneWidget);
      expect(find.text('2 selected'), findsNothing);
      expect(harness.chatHistory.messages.map((m) => m.id), ['3']);
    });

    testWidgets('Delete uses the singular for one message', (tester) async {
      mockPlatform();
      await openChat(tester, [text('1', 'Hello', t0)]);
      await tester.longPress(find.text('Hello'));
      await tester.pump();
      await tester.tap(find.byTooltip('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete 1 message for you?'), findsOneWidget);
    });
  });

  group('reply', () {
    Future<void> sendReply(WidgetTester tester, TestHarness harness) async {
      expect(find.text('Replying to Anil'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'my reply');
      await tester.pump();
      await tester.tap(find.byTooltip('Send'));
      await tester.pump();
      await tester.pump();

      expect(harness.connection.sentChats, [(anil.id, '> Hello\nmy reply')]);
      expect(find.text('Replying to Anil'), findsNothing);
    }

    testWidgets('Reply shows the reply bar and sends a "> " quote', (
      tester,
    ) async {
      mockPlatform();
      final harness = await openChat(tester, [text('1', 'Hello', t0)]);

      await tester.longPress(find.text('Hello'));
      await tester.pump();
      await tester.tap(find.byTooltip('Reply'));
      await tester.pump();
      expect(find.text('1 selected'), findsNothing);

      await sendReply(tester, harness);

      // The new bubble renders the quote card, not the raw "> " text.
      expect(find.text('my reply'), findsOneWidget);
      final messages = harness.chatHistory.messages;
      expect(messages.last.text, '> Hello\nmy reply');
      expect(messages.last.isOutgoing, isTrue);
    });

    testWidgets('swiping a bubble right starts a reply', (tester) async {
      mockPlatform();
      final harness = await openChat(tester, [text('1', 'Hello', t0)]);

      await tester.drag(find.text('Hello'), const Offset(70, 0));
      await tester.pump();

      await sendReply(tester, harness);
    });

    testWidgets('a short swipe does not reply', (tester) async {
      mockPlatform();
      await openChat(tester, [text('1', 'Hello', t0)]);
      await tester.drag(find.text('Hello'), const Offset(25, 0));
      await tester.pump();
      expect(find.text('Replying to Anil'), findsNothing);
    });

    testWidgets('closing the reply bar cancels the reply', (tester) async {
      mockPlatform();
      await openChat(tester, [text('1', 'Hello', t0)]);
      await tester.longPress(find.text('Hello'));
      await tester.pump();
      await tester.tap(find.byTooltip('Reply'));
      await tester.pump();
      await tester.tap(find.byTooltip('Cancel reply'));
      await tester.pump();
      expect(find.text('Replying to Anil'), findsNothing);
    });
  });

  testWidgets('sending plain text adds an outgoing message', (tester) async {
    final harness = await openChat(tester, const []);
    await tester.enterText(find.byType(TextField), 'hi there');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();
    await tester.pump();

    expect(harness.connection.sentChats, [(anil.id, 'hi there')]);
    final context = tester.element(find.byType(ChatPage));
    final stored = context.read<ChatCubit>().getMessagesForPeer(anil.id);
    expect(stored.single.status, MessageStatus.sent);
  });
}
