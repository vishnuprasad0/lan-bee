import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beebeep/features/beebeep/presentation/pages/shell_page.dart';
import 'support/test_harness.dart';

void main() {
  testWidgets('ShellPage shows the app bar, tabs, and network chip', (
    WidgetTester tester,
  ) async {
    final harness = TestHarness();
    await harness.pump(tester, const ShellPage(), startDiscovery: false);
    expect(find.text('LAN Bee'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    // The shell starts discovery itself; nobody is online yet.
    expect(find.text('Searching...'), findsOneWidget);
    expect(harness.discovery.startCount, 1);
  });
  testWidgets('ShellPage asks for a name when none was found', (
    WidgetTester tester,
  ) async {
    final harness = TestHarness();
    await harness.pump(
      tester,
      const ShellPage(askForName: true),
      startDiscovery: false,
    );
    await tester.pump();
    expect(find.text('What should people call you?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '  Maya  ');
    await tester.tap(find.text('Save'));
    // The Searching... spinner never settles, so pump past the dialog exit.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('What should people call you?'), findsNothing);
    expect(harness.settings.displayName, 'Maya');
  });
  testWidgets('ShellPage does not ask when a name exists', (
    WidgetTester tester,
  ) async {
    final harness = TestHarness();
    await harness.pump(tester, const ShellPage(), startDiscovery: false);
    await tester.pump();
    expect(find.text('What should people call you?'), findsNothing);
  });
  testWidgets('ShellPage switches tabs', (WidgetTester tester) async {
    final harness = TestHarness();
    await harness.pump(tester, const ShellPage(), startDiscovery: false);
    await tester.tap(find.text('Files'));
    await tester.pump();
    expect(find.text('Files you send or receive appear here.'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Clear all chat history'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Privacy policy (coming soon)'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Privacy policy (coming soon)'), findsOneWidget);
  });
}
