import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beebeep/features/beebeep/domain/entities/cached_peer.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/presentation/pages/users_tab.dart';
import '../../../support/test_harness.dart';

void main() {
  testWidgets('Users tab empty state shows a spinner, then the Wi-Fi hint', (
    tester,
  ) async {
    final harness = TestHarness();
    await harness.pump(tester, const Scaffold(body: UsersTab()));
    // The fake emits an empty peer list, so there is nothing to show yet.
    expect(find.text('Looking for people on this network...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    await tester.pump(const Duration(seconds: 11));
    expect(
      find.text('Make sure you are on the same Wi-Fi as BeeBEEP desktop.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
  testWidgets('Users tab Retry rescans without clearing the list', (
    tester,
  ) async {
    final harness = TestHarness();
    await harness.pump(tester, const Scaffold(body: UsersTab()));
    await tester.pump(const Duration(seconds: 11));
    expect(harness.discovery.startCount, 1);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump();
    expect(harness.discovery.stopCount, 0);
    expect(harness.discovery.startCount, 1);
    expect(harness.discovery.refreshCount, 1);
  });
  testWidgets('Users tab splits peers into Online and Offline sections', (
    tester,
  ) async {
    const online = Peer(
      id: 'anil-id',
      displayName: 'Anil',
      host: '10.0.0.2',
      port: 6475,
    );
    final harness = TestHarness(
      onlinePeers: const [online],
      cachedPeers: {
        'maya-id': CachedPeer(
          peerId: 'maya-id',
          displayName: 'Maya',
          host: '10.0.0.3',
          port: 6475,
          lastSeen: DateTime.now().subtract(const Duration(days: 3)),
        ),
      },
    );
    await harness.pump(tester, const Scaffold(body: UsersTab()));
    await tester.pump();
    expect(find.text('Online (1)'), findsOneWidget);
    expect(find.text('Offline (1)'), findsOneWidget);
    expect(find.text('Anil'), findsOneWidget);
    expect(find.text('10.0.0.2:6475'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.textContaining('Last seen'), findsOneWidget);
  });
  testWidgets('Users tab search filters by name', (tester) async {
    const anil = Peer(
      id: 'anil-id',
      displayName: 'Anil',
      host: '10.0.0.2',
      port: 6475,
    );
    const maya = Peer(
      id: 'maya-id',
      displayName: 'Maya',
      host: '10.0.0.3',
      port: 6475,
    );
    final harness = TestHarness(onlinePeers: const [anil, maya]);
    await harness.pump(tester, const Scaffold(body: UsersTab()));
    await tester.pump();
    expect(find.text('Online (2)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'may');
    await tester.pump();
    expect(find.text('Online (1)'), findsOneWidget);
    expect(find.text('Anil'), findsNothing);
    expect(find.text('Maya'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);
  });
}
