/// Fixed sizes: tap targets, avatars, status dots.
abstract final class AppSizes {
  static const double tapTarget = 48;
  static const double avatarList = 44;
  static const double avatarAppBar = 36;
  static const double avatarLarge = 72;
  static const double statusDot = 12;
  static const double composerMin = 48;
  static const double emptyStateIcon = 64;
  static const double jumboEmojiSingle = 44;
  static const double jumboEmojiFew = 34;
  static const double thumbMaxWidth = 240;
  static const double thumbMaxHeight = 280;
  static const double thumbMinSide = 96;
  static const int thumbCacheWidth = 480;
  static const double listThumb = 48;
  static const int listThumbCacheWidth = 96;
  static const double previewMaxZoom = 6;
  static const double previewDoubleTapZoom = 2.5;

  /// Window width from which the shell shows a side rail and the chat next
  /// to the list instead of on its own page.
  static const double wideLayout = 840;

  /// Window width from which the side rail shows its labels.
  static const double extendedRail = 1200;

  /// Width of the chat or people list beside the open chat.
  static const double listPane = 360;

  /// Widest a single column of content (Files, Settings) grows.
  static const double contentMaxWidth = 720;
}
