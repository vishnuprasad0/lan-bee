import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/peer.dart';
import '../../../domain/use_cases/connect_to_peer.dart';
import '../../pages/chat_page.dart';
import 'chat_pane_scope.dart';

/// Connects to [peer] (best effort) and opens its chat: in the side pane in
/// wide layouts, otherwise on its own page.
Future<void> openChat(BuildContext context, Peer peer) async {
  final connectToPeer = context.read<ConnectToPeer>();
  final pane = ChatPaneScope.read(context);
  if (pane != null) {
    pane.onOpen(peer);
    await connectToPeer(peer);
    return;
  }
  final navigator = Navigator.of(context);
  await connectToPeer(peer);
  if (!navigator.mounted) return;
  navigator.push(MaterialPageRoute<void>(builder: (_) => ChatPage(peer: peer)));
}
