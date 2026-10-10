import 'package:flutter_test/flutter_test.dart';

import 'package:beebeep/features/beebeep/domain/services/quoted_text.dart';

void main() {
  group('QuotedText.parse', () {
    test('text without a quote has no quote and keeps its body', () {
      final parsed = QuotedText.parse('hello there');
      expect(parsed.quote, isNull);
      expect(parsed.hasQuote, isFalse);
      expect(parsed.body, 'hello there');
    });

    test('desktop style single quote line then reply', () {
      final parsed = QuotedText.parse('> are you coming?\nyes, 5 minutes');
      expect(parsed.quote, 'are you coming?');
      expect(parsed.body, 'yes, 5 minutes');
    });

    test('multiple leading quote lines are joined', () {
      final parsed = QuotedText.parse('> line one\n> line two\nreply');
      expect(parsed.quote, 'line one\nline two');
      expect(parsed.body, 'reply');
    });

    test('a quote that is not leading is not a quote', () {
      final parsed = QuotedText.parse('reply\n> not a quote');
      expect(parsed.quote, isNull);
      expect(parsed.body, 'reply\n> not a quote');
    });

    test('a quote with no reply has an empty body', () {
      final parsed = QuotedText.parse('> only quoted');
      expect(parsed.quote, 'only quoted');
      expect(parsed.body, '');
    });

    test('a bare > line is an empty quote line', () {
      final parsed = QuotedText.parse('> first\n>\n> third\nreply');
      expect(parsed.quote, 'first\n\nthird');
      expect(parsed.body, 'reply');
    });

    test('> without a space is plain text', () {
      final parsed = QuotedText.parse('>5 is bigger');
      expect(parsed.quote, isNull);
      expect(parsed.body, '>5 is bigger');
    });

    test('Windows line endings are handled', () {
      final parsed = QuotedText.parse('> quoted\r\nreply');
      expect(parsed.quote, 'quoted');
      expect(parsed.body, 'reply');
    });

    test('empty text parses to an empty body', () {
      final parsed = QuotedText.parse('');
      expect(parsed.quote, isNull);
      expect(parsed.body, '');
    });
  });

  group('QuotedText.compose', () {
    test('prefixes the quote and puts the reply on the next line', () {
      expect(
        QuotedText.compose(quoted: 'are you coming?', reply: 'yes'),
        '> are you coming?\nyes',
      );
    });

    test('newlines in the quoted text collapse to single spaces', () {
      expect(
        QuotedText.compose(quoted: 'one\n\ntwo\r\n  three', reply: 'ok'),
        '> one two three\nok',
      );
    });

    test('quoted text is trimmed to 120 characters', () {
      final long = 'a' * 300;
      final composed = QuotedText.compose(quoted: long, reply: 'r');
      final quoteLine = composed.split('\n').first;
      expect(quoteLine.startsWith('> '), isTrue);
      expect(quoteLine.length, lessThanOrEqualTo(2 + 120 + 3));
      expect(composed.endsWith('\nr'), isTrue);
    });

    test('an empty quote returns the reply unchanged', () {
      expect(QuotedText.compose(quoted: '  \n ', reply: 'hi'), 'hi');
    });

    test('composed text parses back to the same quote and reply', () {
      final composed = QuotedText.compose(quoted: 'where?', reply: 'here');
      final parsed = QuotedText.parse(composed);
      expect(parsed, const QuotedText(quote: 'where?', body: 'here'));
    });
  });
}
