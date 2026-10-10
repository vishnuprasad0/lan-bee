import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/services/relative_time.dart';
import '../../bloc/peers/peer_presence.dart';
import '../common/peer_avatar.dart';

enum ChatMenuAction { peerInfo, clearChat }

/// Chat app bar: back, avatar, name, `Online` / `Last seen 10:42`, overflow.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.presence,
    required this.onMenuAction,
  });
  final PeerPresence presence;
  final void Function(ChatMenuAction action) onMenuAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peer = presence.peer;
    final name = peer.displayName.isEmpty ? 'Unknown' : peer.displayName;
    final subtitle = presence.isOnline
        ? 'Online'
        : lastSeenLabel(presence.lastSeen, now: DateTime.now());
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          PeerAvatar(
            peerId: peer.id,
            name: name,
            size: AppSizes.avatarAppBar,
            isOnline: presence.isOnline,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<ChatMenuAction>(
          tooltip: 'More options',
          onSelected: onMenuAction,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ChatMenuAction.peerInfo,
              child: Text('Peer info'),
            ),
            PopupMenuItem(
              value: ChatMenuAction.clearChat,
              child: Text('Clear chat'),
            ),
          ],
        ),
      ],
    );
  }
}
