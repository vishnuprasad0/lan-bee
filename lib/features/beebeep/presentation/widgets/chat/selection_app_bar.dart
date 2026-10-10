import 'package:flutter/material.dart';

import '../../../domain/services/message_actions.dart';

String messageActionLabel(MessageAction action) {
  switch (action) {
    case MessageAction.reply:
      return 'Reply';
    case MessageAction.copy:
      return 'Copy';
    case MessageAction.forward:
      return 'Forward';
    case MessageAction.share:
      return 'Share';
    case MessageAction.open:
      return 'Open';
    case MessageAction.info:
      return 'Info';
    case MessageAction.delete:
      return 'Delete';
  }
}

IconData _iconFor(MessageAction action) {
  switch (action) {
    case MessageAction.reply:
      return Icons.reply;
    case MessageAction.copy:
      return Icons.content_copy_outlined;
    case MessageAction.forward:
      return Icons.forward;
    case MessageAction.share:
      return Icons.share_outlined;
    case MessageAction.open:
      return Icons.open_in_new;
    case MessageAction.info:
      return Icons.info_outline;
    case MessageAction.delete:
      return Icons.delete_outline;
  }
}

/// Actions kept as icons in the bar; the rest go to the overflow menu.
const Set<MessageAction> _inlineActions = {
  MessageAction.reply,
  MessageAction.copy,
  MessageAction.forward,
  MessageAction.delete,
};

/// Contextual app bar for selection mode: close, "n selected" (announced to
/// screen readers), and only the actions valid for the selection.
class SelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SelectionAppBar({
    super.key,
    required this.count,
    required this.actions,
    required this.onClose,
    required this.onAction,
  });
  final int count;
  final List<MessageAction> actions;
  final VoidCallback onClose;
  final void Function(MessageAction action) onAction;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inline = actions.where(_inlineActions.contains).toList();
    final overflow = actions.where((a) => !_inlineActions.contains(a)).toList();
    return AppBar(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      leading: IconButton(
        tooltip: 'Cancel selection',
        icon: const Icon(Icons.close),
        onPressed: onClose,
      ),
      title: Semantics(
        liveRegion: true,
        label: '$count selected',
        child: ExcludeSemantics(child: Text('$count selected')),
      ),
      actions: [
        for (final action in inline)
          IconButton(
            tooltip: messageActionLabel(action),
            icon: Icon(_iconFor(action)),
            onPressed: () => onAction(action),
          ),
        if (overflow.isNotEmpty)
          PopupMenuButton<MessageAction>(
            tooltip: 'More actions',
            onSelected: onAction,
            itemBuilder: (context) => [
              for (final action in overflow)
                PopupMenuItem<MessageAction>(
                  value: action,
                  child: Row(
                    children: [
                      Icon(_iconFor(action)),
                      const SizedBox(width: 12),
                      Text(messageActionLabel(action)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
