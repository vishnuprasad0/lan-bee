/// A chat text split into the quoted lines (desktop style `> ` prefix) and the
/// reply itself. Pure Dart; shared by the composer and the bubble renderer.
class QuotedText {
  const QuotedText({required this.quote, required this.body});

  /// Quoted lines without the `> ` prefix, joined by newlines; null if none.
  final String? quote;

  /// The reply text after the quoted lines.
  final String body;

  bool get hasQuote => quote != null;

  /// Maximum characters of quoted text on the wire.
  static const int maxQuoteLength = 120;

  /// Parses leading lines that start with `> ` (or are a bare `>`). Everything after the first non-quote line is the body.
  static QuotedText parse(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final quoted = <String>[];
    var index = 0;
    while (index < lines.length && _isQuoteLine(lines[index])) {
      quoted.add(_stripPrefix(lines[index]));
      index++;
    }
    if (quoted.isEmpty) return QuotedText(quote: null, body: text);
    final body = lines.sublist(index).join('\n').trim();
    return QuotedText(quote: quoted.join('\n').trim(), body: body);
  }

  /// Builds the wire text for a reply: `> quoted\nreply`. The quoted text is
  /// collapsed to a single paragraph and trimmed to [maxQuoteLength]
  /// characters. An empty quote returns the reply unchanged.
  static String compose({required String quoted, required String reply}) {
    final single = quoted.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (single.isEmpty) return reply;
    final limited = single.length > maxQuoteLength
        ? '${single.substring(0, maxQuoteLength).trimRight()}...'
        : single;
    return '> $limited\n$reply';
  }

  static bool _isQuoteLine(String line) => line == '>' || line.startsWith('> ');
  static String _stripPrefix(String line) {
    return line.length <= 2 ? '' : line.substring(2);
  }

  @override
  bool operator ==(Object other) =>
      other is QuotedText && other.quote == quote && other.body == body;

  @override
  int get hashCode => Object.hash(quote, body);
}
