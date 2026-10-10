import 'package:flutter/widgets.dart';

import '../../../domain/entities/peer.dart';

/// Present in wide layouts, where a chat opens in the pane beside the list
/// instead of on its own page.
class ChatPaneScope extends InheritedWidget {
  const ChatPaneScope({
    super.key,
    required this.openPeerId,
    required this.onOpen,
    required super.child,
  });

  /// Peer whose chat is in the pane, if any.
  final String? openPeerId;

  /// Shows the chat with a peer in the pane.
  final void Function(Peer peer) onOpen;

  static ChatPaneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatPaneScope>();

  /// Like [maybeOf] without rebuilding on change; for callbacks.
  static ChatPaneScope? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ChatPaneScope>();

  /// True when [peerId]'s chat is open in the pane; for highlighting rows.
  static bool isOpen(BuildContext context, String peerId) =>
      maybeOf(context)?.openPeerId == peerId;

  @override
  bool updateShouldNotify(ChatPaneScope oldWidget) =>
      openPeerId != oldWidget.openPeerId || onOpen != oldWidget.onOpen;
}
