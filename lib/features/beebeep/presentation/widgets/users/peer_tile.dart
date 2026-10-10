import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/services/relative_time.dart';
import '../../bloc/peers/peer_presence.dart';
import '../common/chat_pane_scope.dart';
import '../common/peer_avatar.dart';

/// One row in the Users tab.
class PeerTile extends StatelessWidget {
  const PeerTile({
    super.key,
    required this.presence,
    required this.now,
    required this.onTap,
    required this.onInfo,
  });

  final PeerPresence presence;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final peer = presence.peer;
    final name = peer.displayName.isEmpty ? 'Unknown' : peer.displayName;
    final subtitle = presence.isOnline
        ? '${peer.host}:${peer.port}'
        : lastSeenLabel(presence.lastSeen, now: now);

    return Ink(
      color: ChatPaneScope.isOpen(context, peer.id)
          ? theme.colorScheme.secondaryContainer
          : null,
      child: InkWell(
        onTap: onTap,
        onLongPress: onInfo,
        onSecondaryTap: onInfo,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              top: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              children: [
                PeerAvatar(
                  peerId: peer.id,
                  name: name,
                  size: AppSizes.avatarList,
                  isOnline: presence.isOnline,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Peer info',
                  constraints: const BoxConstraints(
                    minWidth: AppSizes.tapTarget,
                    minHeight: AppSizes.tapTarget,
                  ),
                  onPressed: onInfo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
