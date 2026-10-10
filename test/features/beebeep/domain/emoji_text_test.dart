import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/services/emoji_text.dart';

void main() {
  group('jumboEmojiCount', () {
    test('counts single emoji, including text-style ones from desktop', () {
      expect(jumboEmojiCount('\u263A'), 1); // smiling face, as sent by desktop
      expect(jumboEmojiCount('\u{1F622}'), 1);
      expect(jumboEmojiCount(' \u{1F628} '), 1);
    });

    test('counts up to three emoji', () {
      expect(jumboEmojiCount('\u{1F600}\u{1F600}'), 2);
      expect(jumboEmojiCount('\u{1F600} \u{1F44D} \u2764\uFE0F'), 3);
    });

    test('treats modifiers, ZWJ sequences, flags and keycaps as one', () {
      expect(jumboEmojiCount('\u{1F44D}\u{1F3FD}'), 1); // thumbs up + skin
      expect(
        jumboEmojiCount('\u{1F468}\u200D\u{1F469}\u200D\u{1F467}'),
        1,
      ); // family
      expect(jumboEmojiCount('\u{1F1EE}\u{1F1F3}'), 1); // flag
      expect(jumboEmojiCount('1\uFE0F\u20E3'), 1); // keycap
    });

    test('returns null for text, mixed content, or too many emoji', () {
      expect(jumboEmojiCount('Hi'), isNull);
      expect(jumboEmojiCount('ok \u{1F44D}'), isNull);
      expect(jumboEmojiCount('1'), isNull);
      expect(jumboEmojiCount(''), isNull);
      expect(jumboEmojiCount('\u{1F600}\u{1F600}\u{1F600}\u{1F600}'), isNull);
    });
  });
}
