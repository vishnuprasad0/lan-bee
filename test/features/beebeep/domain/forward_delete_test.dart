import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/entities/peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/delete_messages.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/forward_messages.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/send_chat_to_peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/send_file_to_peer.dart';
import 'package:beebeep/features/beebeep/domain/use_cases/send_voice_message_to_peer.dart';

import '../../../support/test_harness.dart';

ChatMessage msg(
  String id,
  DateTime at, {
  String text = 'hi',
  MessageType type = MessageType.text,
  String? path,
}) {
  return ChatMessage(
    id: id,
    peerId: 'src',
    text: text,
    timestamp: at,
    isOutgoing: false,
    type: type,
    fileName: path == null ? null : 'f.bin',
    filePath: path,
    duration: type == MessageType.voice ? const Duration(seconds: 3) : null,
  );
}

const anil = Peer(id: 'a', displayName: 'Anil', host: '10.0.0.2', port: 1);
const bina = Peer(id: 'b', displayName: 'Bina', host: '10.0.0.3', port: 1);

void main() {
  final t0 = DateTime(2026, 10, 6, 9);

  group('DeleteMessages', () {
    test('removes only the given ids', () {
      final all = [msg('1', t0), msg('2', t0), msg('3', t0)];
      final left = const DeleteMessages()(all, {'1', '3'});
      expect(left.map((m) => m.id), ['2']);
    });

    test('unknown ids and empty set change nothing', () {
      final all = [msg('1', t0)];
      expect(const DeleteMessages()(all, {'x'}), all);
      expect(const DeleteMessages()(all, const {}), all);
    });
  });

  group('ForwardMessages', () {
    late FakeConnectionRepository connection;
    late ForwardMessages forward;

    ForwardMessages build(Set<String> existing) {
      connection = FakeConnectionRepository();
      return ForwardMessages(
        sendChat: SendChatToPeer(connection),
        sendFile: SendFileToPeer(connection),
        sendVoice: SendVoiceMessageToPeer(connection),
        files: FakeLocalFileRepository(existing),
        now: () => DateTime(2026, 10, 7, 12),
      );
    }

    test('text goes to every target as a new outgoing message', () async {
      forward = build({});
      final result = await forward(
        messages: [
          msg('1', t0, text: 'one'),
          msg('2', t0, text: 'two'),
        ],
        targets: const [anil, bina],
      );

      expect(connection.sentChats, [
        ('a', 'one'),
        ('b', 'one'),
        ('a', 'two'),
        ('b', 'two'),
      ]);
      expect(result.forwardedCount, 4);
      expect(result.skippedCount, 0);
      expect(result.chatCount, 2);
      expect(result.sent.every((m) => m.isOutgoing), isTrue);
      expect(result.sent.map((m) => m.peerId), ['a', 'b', 'a', 'b']);
      expect(result.sent.map((m) => m.id).toSet().length, 4);
      // Strictly increasing timestamps keep the order.
      for (var i = 1; i < result.sent.length; i++) {
        expect(
          result.sent[i].timestamp.isAfter(result.sent[i - 1].timestamp),
          isTrue,
        );
      }
    });

    test('messages are forwarded in time order', () async {
      forward = build({});
      await forward(
        messages: [
          msg('late', t0.add(const Duration(minutes: 5)), text: 'second'),
          msg('early', t0, text: 'first'),
        ],
        targets: const [anil],
      );
      expect(connection.sentChats.map((c) => c.$2), ['first', 'second']);
    });

    test(
      'files with the original path are sent, missing ones skipped',
      () async {
        forward = build({'/ok.bin'});
        final result = await forward(
          messages: [
            msg('1', t0, type: MessageType.file, path: '/ok.bin'),
            msg('2', t0, type: MessageType.file, path: '/gone.bin'),
            msg('3', t0, type: MessageType.file),
          ],
          targets: const [anil, bina],
        );

        expect(connection.sentFiles, [('a', 'f.bin'), ('b', 'f.bin')]);
        expect(result.forwardedCount, 2);
        expect(result.skippedCount, 2);
        expect(result.chatCount, 2);
        expect(result.sent.first.filePath, '/ok.bin');
      },
    );

    test('voice messages keep their duration', () async {
      forward = build({'/v.aac'});
      final result = await forward(
        messages: [msg('1', t0, type: MessageType.voice, path: '/v.aac')],
        targets: const [anil],
      );
      expect(result.forwardedCount, 1);
      expect(result.sent.single.type, MessageType.voice);
      expect(result.sent.single.duration, const Duration(seconds: 3));
    });

    test('nothing to send when every file is missing', () async {
      forward = build({});
      final result = await forward(
        messages: [msg('1', t0, type: MessageType.file, path: '/gone')],
        targets: const [anil],
      );
      expect(result.forwardedCount, 0);
      expect(result.skippedCount, 1);
      expect(result.chatCount, 0);
      expect(result.sent, isEmpty);
    });
  });
}
