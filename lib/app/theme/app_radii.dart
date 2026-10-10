import 'package:flutter/painting.dart';

/// Corner radii shared by every screen.
abstract final class AppRadii {
  static const double bubble = 18;
  static const double bubbleTail = 4;
  static const double card = 12;
  static const double field = 24;
  static const double chip = 999;
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get fieldRadius => BorderRadius.circular(field);
  static BorderRadius get chipRadius => BorderRadius.circular(chip);

  /// Message bubble with a small tail corner on the sender's side.
  static BorderRadius bubbleFor({required bool isOutgoing}) {
    return BorderRadius.only(
      topLeft: const Radius.circular(bubble),
      topRight: const Radius.circular(bubble),
      bottomLeft: Radius.circular(isOutgoing ? bubble : bubbleTail),
      bottomRight: Radius.circular(isOutgoing ? bubbleTail : bubble),
    );
  }
}
