import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation_summary.dart';
import '../../domain/entities/peer.dart';
import '../bloc/chat/chat_cubit.dart';
import '../bloc/chat/chat_state.dart';
import '../bloc/conversations/conversation_summaries.dart';
import '../bloc/peers/peers_cubit.dart';
import '../bloc/peers/peers_state.dart';
import '../bloc/read_state/read_state.dart';
import '../bloc/read_state/read_state_cubit.dart';
import '../widgets/chats/conversation_tile.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/open_chat.dart';

/// Conversations with history, newest first.
class ChatsTab extends StatelessWidget {
  const ChatsTab({super.key, required this.onGoToUsers});

  final VoidCallback onGoToUsers;

  @override
  Widget build(BuildContext context) {
    final peersState = context.watch<PeersCubit>().state;
    final chatState = context.watch<ChatCubit>().state;
    final readState = context.watch<ReadStateCubit>().state;
    return _ChatsList(
      peers: peersState,
      chat: chatState,
      read: readState,
      onGoToUsers: onGoToUsers,
    );
  }
}

class _ChatsList extends StatelessWidget {
  const _ChatsList({
    required this.peers,
    required this.chat,
    required this.read,
    required this.onGoToUsers,
  });

  final PeersState peers;
  final ChatState chat;
  final ReadState read;
  final VoidCallback onGoToUsers;

  @override
  Widget build(BuildContext context) {
    final summaries = conversationSummariesOf(
      peers: peers,
      chat: chat,
      read: read,
    );

    if (summaries.isEmpty) {
      return EmptyState(
        icon: Icons.hive_outlined,
        title: 'No chats yet',
        body: 'People on the same Wi-Fi show up in Users.',
        actionLabel: 'Go to Users',
        onAction: onGoToUsers,
      );
    }

    final now = DateTime.now();
    return ListView.builder(
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return ConversationTile(
          summary: summary,
          now: now,
          onTap: () => _open(context, summary),
          onLongPress: () => _showActions(context, summary),
        );
      },
    );
  }

  Peer? _peerFor(ConversationSummary summary) {
    for (final presence in peers.peers) {
      if (presence.peer.id == summary.peerId) return presence.peer;
    }
    return null;
  }

  void _open(BuildContext context, ConversationSummary summary) {
    final peer = _peerFor(summary);
    if (peer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${summary.displayName} has not been seen yet.'),
        ),
      );
      return;
    }
    openChat(context, peer);
  }

  Future<void> _showActions(
    BuildContext context,
    ConversationSummary summary,
  ) async {
    final readCubit = context.read<ReadStateCubit>();
    final chatCubit = context.read<ChatCubit>();

    final action = await showModalBottomSheet<_ChatAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.done_all),
              title: const Text('Mark as read'),
              enabled: summary.hasUnread,
              onTap: () => Navigator.pop(sheetContext, _ChatAction.markRead),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: const Text('Clear chat'),
              onTap: () => Navigator.pop(sheetContext, _ChatAction.clear),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _ChatAction.markRead:
        readCubit.markRead(summary.peerId, upTo: summary.lastMessageTime);
      case _ChatAction.clear:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Clear chat with ${summary.displayName}?'),
            content: const Text(
              'Messages are removed from this device only. '
              'They stay on the other device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Clear'),
              ),
            ],
          ),
        );
        if (confirmed == true) chatCubit.clearMessagesForPeer(summary.peerId);
    }
  }
}

enum _ChatAction { markRead, clear }
