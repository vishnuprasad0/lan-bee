import 'package:flutter/foundation.dart';

/// True on Windows, macOS and Linux, where a mouse and keyboard are expected.
bool get isDesktopPlatform => switch (defaultTargetPlatform) {
  TargetPlatform.windows ||
  TargetPlatform.macOS ||
  TargetPlatform.linux => true,
  _ => false,
};
