import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/presentation/pages/file_preview_page.dart';
import '../../../support/temp_files.dart';
import '../../../support/test_harness.dart';

ChatMessage fileMsg(String name, String? path, {int size = 100}) {
  return ChatMessage(
    id: 'm1',
    peerId: 'p1',
    text: name,
    timestamp: DateTime(2026, 10, 6, 9, 5),
    isOutgoing: false,
    type: MessageType.file,
    fileName: name,
    fileSize: size,
    filePath: path,
  );
}

void main() {
  testWidgets('image file shows an Image with its name and size', (
    tester,
  ) async {
    final path = await writeTempFile('dot.png', tinyPng);
    await TestHarness().pump(
      tester,
      FilePreviewPage(message: fileMsg('dot.png', path, size: 2048)),
      startDiscovery: false,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('dot.png'), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Open with'), findsOneWidget);
  });
  testWidgets('text file shows its content without a banner when small', (
    tester,
  ) async {
    final path = await writeTempFile('notes.txt', utf8.encode('hello preview'));
    await TestHarness().pump(
      tester,
      FilePreviewPage(message: fileMsg('notes.txt', path)),
      startDiscovery: false,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text('hello preview'), findsOneWidget);
    expect(find.textContaining('Showing the first'), findsNothing);
  });
  testWidgets('long text file is cut at the limit and shows the banner', (
    tester,
  ) async {
    final body = 'x' * 3000;
    final path = await writeTempFile('big.log', utf8.encode(body));
    await TestHarness().pump(
      tester,
      FilePreviewPage(message: fileMsg('big.log', path), textLimitBytes: 2048),
      startDiscovery: false,
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(find.text('Showing the first 2 KB'), findsOneWidget);
    expect(find.text('x' * 2048), findsOneWidget);
  });
  testWidgets('unknown extension shows the info card with actions', (
    tester,
  ) async {
    final path = await writeTempFile('setup.exe', const [1, 2, 3]);
    await TestHarness().pump(
      tester,
      FilePreviewPage(message: fileMsg('setup.exe', path)),
      startDiscovery: false,
    );
    expect(find.text('Open with'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('File no longer on this device'), findsNothing);
  });
  testWidgets('missing file says it is no longer on this device', (
    tester,
  ) async {
    await TestHarness().pump(
      tester,
      FilePreviewPage(message: fileMsg('photo.png', '/no/such/photo.png')),
      startDiscovery: false,
    );
    expect(find.text('File no longer on this device'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Open with'), findsNothing);
  });
}
