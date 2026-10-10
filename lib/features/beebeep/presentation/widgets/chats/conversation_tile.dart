import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/conversation_summary.dart';
import '../../../domain/services/relative_time.dart';
import '../common/chat_pane_scope.dart';
import '../common/peer_avatar.dart';

/// One row in the Chats tab.
class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.summary,
    required this.now,
    required this.onTap,
    required this.onLongPress,
  });

  final ConversationSummary summary;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = summary.hasUnread;
    final time = relativeTimeLabel(summary.lastMessageTime, now: now);

    final previewIcon = switch (summary.previewType) {
      MessageType.file => Icons.insert_drive_file_outlined,
      MessageType.voice => Icons.mic_none,
      MessageType.text => null,
    };

    return Semantics(
      label:
          '${summary.displayName}, ${summary.preview}, $time'
          '${unread ? ', ${summary.unreadCount} unread' : ''}',
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Ink(
        color: ChatPaneScope.isOpen(context, summary.peerId)
            ? scheme.secondaryContainer
            : null,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTap: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  PeerAvatar(
                    peerId: summary.peerId,
                    name: summary.displayName,
                    size: AppSizes.avatarList,
                    isOnline: summary.isOnline,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: unread
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (previewIcon != null) ...[
                              Icon(
                                previewIcon,
                                size: 16,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Expanded(
                              child: Text(
                                summary.preview,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: unread
                                      ? scheme.onSurface
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: unread
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _UnreadBadge(count: summary.unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadii.chipRadius,
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
