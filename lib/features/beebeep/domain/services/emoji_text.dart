/// Largest emoji-only message shown as large emoji without a bubble.
const int maxJumboEmoji = 3;

final RegExp _emojiCluster = RegExp(
  r'\p{Regional_Indicator}{2}'
  r'|[#*0-9]\uFE0F?\u20E3'
  r'|\p{Extended_Pictographic}[\uFE0E\uFE0F]?\p{Emoji_Modifier}?'
  r'(?:\u200D\p{Extended_Pictographic}[\uFE0E\uFE0F]?\p{Emoji_Modifier}?)*',
  unicode: true,
);

/// Number of emoji in [text] when it holds only emoji (whitespace allowed)
/// and at most [maxJumboEmoji] of them; otherwise null.
int? jumboEmojiCount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  var count = 0;
  var index = 0;
  while (index < trimmed.length) {
    final char = trimmed[index];
    if (char == ' ' || char == '\n' || char == '\t') {
      index++;
      continue;
    }
    final match = _emojiCluster.matchAsPrefix(trimmed, index);
    if (match == null || match.end == index) return null;
    count++;
    if (count > maxJumboEmoji) return null;
    index = match.end;
  }
  return count == 0 ? null : count;
}
