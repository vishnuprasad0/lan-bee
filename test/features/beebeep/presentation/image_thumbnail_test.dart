import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/presentation/pages/chat_page.dart';
import 'package:beebeep/features/beebeep/presentation/pages/file_preview_page.dart';
import '../../../support/temp_files.dart';
import '../../../support/test_harness.dart';

const anil = Peer(
  id: 'anil-id',
  displayName: 'Anil',
  host: '10.0.0.2',
  port: 6475,
);
void main() {
  final t0 = DateTime(2026, 10, 6, 9, 5);
  Future<void> openWithImage(WidgetTester tester, {String? path}) async {
    final filePath = path ?? await writeTempFile('dot.png', tinyPng);
    final messages = [
      ChatMessage(
        id: 'img',
        peerId: anil.id,
        text: 'dot.png',
        timestamp: t0,
        isOutgoing: false,
        type: MessageType.file,
        fileName: 'dot.png',
        fileSize: 70,
        filePath: filePath,
      ),
      ChatMessage(
        id: 'txt',
        peerId: anil.id,
        text: 'Hello',
        timestamp: t0.add(const Duration(minutes: 1)),
        isOutgoing: false,
      ),
    ];
    await TestHarness(
      onlinePeers: const [anil],
      messages: messages,
    ).pump(tester, const ChatPage(peer: anil));
  }

  testWidgets('image message renders a thumbnail, not the file row', (
    tester,
  ) async {
    await openWithImage(tester);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('dot.png'), findsNothing);
    expect(find.text('09:05'), findsOneWidget);
  });
  testWidgets('tap opens the preview page', (tester) async {
    await openWithImage(tester);
    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    expect(find.byType(FilePreviewPage), findsOneWidget);
  });
  testWidgets('in selection mode tap toggles selection and does not open', (
    tester,
  ) async {
    await openWithImage(tester);
    await tester.longPress(find.text('Hello'));
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);
    await tester.tap(find.byType(Image));
    await tester.pump();
    expect(find.text('2 selected'), findsOneWidget);
    expect(find.byType(FilePreviewPage), findsNothing);
  });
  testWidgets('long press on the thumbnail enters selection mode', (
    tester,
  ) async {
    await openWithImage(tester);
    await tester.longPress(find.byType(Image));
    await tester.pump();
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.byType(FilePreviewPage), findsNothing);
  });
  testWidgets('missing image keeps the greyed tile', (tester) async {
    await openWithImage(tester, path: '/no/such/dot.png');
    expect(find.byType(Image), findsNothing);
    expect(find.text('dot.png'), findsOneWidget);
    expect(find.text('File no longer on this device'), findsOneWidget);
  });
}
