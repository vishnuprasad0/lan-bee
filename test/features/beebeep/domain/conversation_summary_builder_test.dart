import 'package:flutter_test/flutter_test.dart';
import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/domain/services/conversation_summary_builder.dart';

ChatMessage _msg(
  String id,
  String peerId,
  DateTime at, {
  String text = 'hi',
  bool outgoing = false,
  MessageType type = MessageType.text,
  String? fileName,
  Duration? duration,
}) {
  return ChatMessage(
    id: id,
    peerId: peerId,
    text: text,
    timestamp: at,
    isOutgoing: outgoing,
    type: type,
    fileName: fileName,
    duration: duration,
  );
}

void main() {
  const builder = ConversationSummaryBuilder();
  const anil = Peer(id: 'a', displayName: 'Anil', host: '10.0.0.2', port: 6475);
  const maya = Peer(id: 'm', displayName: 'Maya', host: '10.0.0.3', port: 6475);
  final t0 = DateTime(2026, 10, 7, 10);
  List<dynamic> build(
    List<ChatMessage> messages, {
    Map<String, DateTime> lastRead = const {},
    Set<String> online = const {},
  }) {
    return builder.build(
      messages: messages,
      peers: const [anil, maya],
      onlinePeerIds: online,
      lastRead: lastRead,
    );
  }

  test('no messages gives no conversations', () {
    expect(build(const []), isEmpty);
  });
  test('sorts by last message time, newest first', () {
    final result = build([
      _msg('1', 'a', t0),
      _msg('2', 'm', t0.add(const Duration(minutes: 5))),
      _msg('3', 'a', t0.add(const Duration(minutes: 1))),
    ]);
    expect(result.map((s) => s.peerId), ['m', 'a']);
  });
  test('last message is picked by time, not list order', () {
    final result = build([
      _msg('2', 'a', t0.add(const Duration(minutes: 9)), text: 'newest'),
      _msg('1', 'a', t0, text: 'oldest'),
    ]);
    expect(result.single.preview, 'newest');
  });
  group('unread', () {
    test('counts only incoming messages after lastRead', () {
      final result = build(
        [
          _msg('1', 'a', t0),
          _msg('2', 'a', t0.add(const Duration(minutes: 1))),
          _msg('3', 'a', t0.add(const Duration(minutes: 2))),
          _msg('4', 'a', t0.add(const Duration(minutes: 3)), outgoing: true),
        ],
        lastRead: {'a': t0.add(const Duration(seconds: 30))},
      );
      expect(result.single.unreadCount, 2);
      expect(result.single.hasUnread, isTrue);
    });
    test('a message exactly at lastRead counts as read', () {
      final result = build([_msg('1', 'a', t0)], lastRead: {'a': t0});
      expect(result.single.unreadCount, 0);
    });
    test('no lastRead means every incoming message is unread', () {
      final result = build([
        _msg('1', 'a', t0),
        _msg('2', 'a', t0, outgoing: true),
      ]);
      expect(result.single.unreadCount, 1);
    });
    test('is tracked per peer', () {
      final result = build(
        [_msg('1', 'a', t0), _msg('2', 'm', t0)],
        lastRead: {'a': t0},
      );
      final byId = {for (final s in result) s.peerId: s.unreadCount};
      expect(byId, {'a': 0, 'm': 1});
    });
  });
  group('preview', () {
    test('incoming text has no prefix, outgoing gets You:', () {
      expect(
        build([_msg('1', 'a', t0, text: 'hello')]).single.preview,
        'hello',
      );
      expect(
        build([
          _msg('1', 'a', t0, text: 'hello', outgoing: true),
        ]).single.preview,
        'You: hello',
      );
    });
    test('file shows the file name', () {
      final s = build([
        _msg('1', 'a', t0, type: MessageType.file, fileName: 'report.pdf'),
      ]).single;
      expect(s.preview, 'report.pdf');
      expect(s.previewType, MessageType.file);
    });
    test('voice shows Voice message and duration', () {
      final s = build([
        _msg(
          '1',
          'a',
          t0,
          type: MessageType.voice,
          duration: const Duration(seconds: 72),
          outgoing: true,
        ),
      ]).single;
      expect(s.preview, 'You: Voice message 1:12');
      expect(s.previewType, MessageType.voice);
    });
    test('voice without duration omits it', () {
      final s = build([_msg('1', 'a', t0, type: MessageType.voice)]).single;
      expect(s.preview, 'Voice message');
    });
    test('leading quote lines are stripped', () {
      final s = build([
        _msg('1', 'a', t0, text: '> earlier text\n> more\nmy reply'),
      ]).single;
      expect(s.preview, 'my reply');
    });
    test('a quote that is not leading is kept', () {
      final s = build([_msg('1', 'a', t0, text: 'see\n> quoted')]).single;
      expect(s.preview, 'see > quoted');
    });
    test('a message that is only a quote falls back to the quoted text', () {
      final s = build([_msg('1', 'a', t0, text: '> just this')]).single;
      expect(s.preview, 'just this');
    });
    test('multi-line text collapses to one line', () {
      final s = build([_msg('1', 'a', t0, text: 'a\n\nb')]).single;
      expect(s.preview, 'a b');
    });
  });
  test('uses peer name, online flag, and Unknown for missing peers', () {
    final result = build(
      [_msg('1', 'a', t0), _msg('2', 'zzz', t0)],
      online: {'a'},
    );
    final byId = {for (final s in result) s.peerId: s};
    expect(byId['a']!.displayName, 'Anil');
    expect(byId['a']!.isOnline, isTrue);
    expect(byId['zzz']!.displayName, 'Unknown');
    expect(byId['zzz']!.isOnline, isFalse);
  });
}
