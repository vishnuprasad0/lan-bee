import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/entities/chat_message.dart';
import 'package:beebeep/features/beebeep/domain/services/message_actions.dart';
import 'package:beebeep/features/beebeep/domain/services/message_copy_formatter.dart';

ChatMessage msg(
  String id,
  DateTime at, {
  String text = 'hi',
  bool outgoing = false,
  MessageType type = MessageType.text,
}) {
  return ChatMessage(
    id: id,
    peerId: 'p',
    text: text,
    timestamp: at,
    isOutgoing: outgoing,
    type: type,
    fileName: type == MessageType.text ? null : 'f.pdf',
    filePath: type == MessageType.text ? null : '/x/f.pdf',
  );
}

void main() {
  final t0 = DateTime(2026, 10, 6, 9, 5);

  group('formatMessagesForCopy', () {
    String nameFor(ChatMessage m) => m.isOutgoing ? 'You' : 'Anil';

    test('one text message copies its text only', () {
      expect(
        formatMessagesForCopy([msg('a', t0, text: 'hello')], nameFor: nameFor),
        'hello',
      );
    });

    test('several messages use [d MMM HH:mm] Name: text in time order', () {
      final out = formatMessagesForCopy([
        msg(
          'b',
          t0.add(const Duration(minutes: 3)),
          text: 'two',
          outgoing: true,
        ),
        msg('a', t0, text: 'one'),
      ], nameFor: nameFor);
      expect(out, '[6 Oct 09:05] Anil: one\n[6 Oct 09:08] You: two');
    });

    test('non-text messages are left out of a multi copy', () {
      final out = formatMessagesForCopy([
        msg('a', t0, text: 'one'),
        msg('f', t0.add(const Duration(minutes: 1)), type: MessageType.file),
      ], nameFor: nameFor);
      expect(out, '[6 Oct 09:05] Anil: one');
    });
  });

  group('availableMessageActions', () {
    bool allAvailable(ChatMessage m) => true;
    bool noneAvailable(ChatMessage m) => false;

    test('one text message', () {
      expect(
        availableMessageActions([msg('a', t0)], fileAvailable: allAvailable),
        [
          MessageAction.reply,
          MessageAction.copy,
          MessageAction.forward,
          MessageAction.info,
          MessageAction.delete,
        ],
      );
    });

    test('one file message with the file present', () {
      expect(
        availableMessageActions([
          msg('a', t0, type: MessageType.file),
        ], fileAvailable: allAvailable),
        [
          MessageAction.reply,
          MessageAction.forward,
          MessageAction.share,
          MessageAction.open,
          MessageAction.info,
          MessageAction.delete,
        ],
      );
    });

    test('a missing file cannot be shared or opened', () {
      final actions = availableMessageActions([
        msg('a', t0, type: MessageType.file),
      ], fileAvailable: noneAvailable);
      expect(actions, isNot(contains(MessageAction.share)));
      expect(actions, isNot(contains(MessageAction.open)));
    });

    test('a voice message can be shared but not opened', () {
      final actions = availableMessageActions([
        msg('a', t0, type: MessageType.voice),
      ], fileAvailable: allAvailable);
      expect(actions, contains(MessageAction.share));
      expect(actions, isNot(contains(MessageAction.open)));
    });

    test('two messages only offer copy, forward, delete', () {
      expect(
        availableMessageActions([
          msg('a', t0),
          msg('b', t0),
        ], fileAvailable: allAvailable),
        [MessageAction.copy, MessageAction.forward, MessageAction.delete],
      );
    });

    test('two files have no copy', () {
      expect(
        availableMessageActions([
          msg('a', t0, type: MessageType.file),
          msg('b', t0, type: MessageType.file),
        ], fileAvailable: allAvailable),
        [MessageAction.forward, MessageAction.delete],
      );
    });

    test('empty selection has no actions', () {
      expect(
        availableMessageActions(const [], fileAvailable: allAvailable),
        isEmpty,
      );
    });
  });
}
