import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:beebeep/app/theme/app_colors.dart';
import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/services/chat_timeline.dart';
import '../../../domain/services/emoji_text.dart';
import '../../../domain/services/preview_kind.dart';
import '../../../domain/services/quoted_text.dart';
import '../../services/file_actions.dart';

import 'file_tile.dart';
import 'image_tile.dart';
import 'quote_card.dart';
import 'voice_tile.dart';

/// True for an image or SVG file that is still on this device: it is drawn as
/// a thumbnail instead of the file row.
bool isThumbnailMessage(ChatMessage message) {
  return message.type == MessageType.file &&
      hasThumbnail(previewKindFor(message.fileName)) &&
      localFileExists(message.filePath);
}

/// Horizontal drag distance that starts a reply.
const double swipeReplyDistance = 40;

/// One chat bubble with grouping, quote card, content, footer, selection
/// highlight, and swipe-to-reply.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.entry,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSwipeReply,
  });
  final MessageEntry entry;
  final bool selected;
  final bool selectionMode;

  /// Called on tap while in selection mode.
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onSwipeReply;

  @override
  Widget build(BuildContext context) {
    final message = entry.message;
    final colors = AppColors.of(context);
    final theme = Theme.of(context);
    final outgoing = message.isOutgoing;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final radius = entry.isLastInGroup
        ? AppRadii.bubbleFor(isOutgoing: outgoing)
        : BorderRadius.circular(AppRadii.bubble);
    final jumbo = message.type == MessageType.text
        ? jumboEmojiCount(message.text)
        : null;
    final thumbnail = isThumbnailMessage(message);
    // The bubble sizes to its content: no child may expand to the max width.
    Widget bubble = jumbo != null
        ? _JumboEmoji(message: message, count: jumbo)
        : DecoratedBox(
            decoration: BoxDecoration(
              color: outgoing ? colors.bubbleOutgoing : colors.bubbleIncoming,
              borderRadius: radius,
              border: outgoing
                  ? null
                  : Border.all(color: theme.colorScheme.outline),
            ),
            child: Padding(
              padding: thumbnail
                  ? const EdgeInsets.all(AppSpacing.xs)
                  : const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm + 2,
                      AppSpacing.xs + 2,
                    ),
              child: _Content(message: message, selectionMode: selectionMode),
            ),
          );
    bubble = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: bubble,
    );
    Widget row = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        entry.continuesPrevious ? AppSpacing.xs : AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Align(
        alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
    row = _SwipeToReply(
      enabled: !selectionMode,
      onReply: onSwipeReply,
      child: row,
    );
    if (selected) {
      row = ColoredBox(color: colors.bubbleSelected, child: row);
    }
    return Semantics(
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: selectionMode ? onTap : null,
        onLongPress: () {
          HapticFeedback.selectionClick();
          onLongPress();
        },
        // Right click selects, like a long press on touch.
        onSecondaryTap: onLongPress,
        child: row,
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.message, required this.selectionMode});
  final ChatMessage message;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.file:
        if (isThumbnailMessage(message)) {
          return ImageTile(
            message: message,
            onTapEnabled: !selectionMode,
            footer: _Footer(message: message, onScrim: true),
          );
        }
        return _WithFooterBelow(
          message: message,
          child: FileTile(message: message, onTapEnabled: !selectionMode),
        );
      case MessageType.voice:
        return _WithFooterBelow(
          message: message,
          child: VoiceTile(message: message, enabled: !selectionMode),
        );
      case MessageType.text:
        final quoted = QuotedText.parse(message.text);
        final body = _TextWithInlineFooter(text: quoted.body, message: message);
        if (quoted.quote == null) return body;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            QuoteCard(text: quoted.quote!),
            const SizedBox(height: AppSpacing.xs),
            body,
          ],
        );
    }
  }
}

/// Text followed by the time/ticks footer. A short message keeps the footer on
/// the same line; a long one wraps it to the next line, aligned to the end.
/// Wrap shrinks to its widest run, so the bubble fits the text.
class _TextWithInlineFooter extends StatelessWidget {
  const _TextWithInlineFooter({required this.text, required this.message});
  final String text;
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: 2,
      children: [
        if (text.isNotEmpty)
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: _Footer(message: message),
        ),
      ],
    );
  }
}

/// File and voice tiles with the footer under them, aligned to the end.
class _WithFooterBelow extends StatelessWidget {
  const _WithFooterBelow({required this.message, required this.child});
  final ChatMessage message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: AppSpacing.xs),
        _Footer(message: message),
      ],
    );
  }
}

/// One to three emoji shown large without a bubble, like other messengers.
class _JumboEmoji extends StatelessWidget {
  const _JumboEmoji({required this.message, required this.count});
  final ChatMessage message;
  final int count;

  @override
  Widget build(BuildContext context) {
    final size = count == 1
        ? AppSizes.jumboEmojiSingle
        : AppSizes.jumboEmojiFew;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: message.isOutgoing
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.text.trim(),
            style: TextStyle(fontSize: size, height: 1.15),
          ),
          _Footer(message: message),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.message, this.onScrim = false});
  final ChatMessage message;

  /// True over an image thumbnail: light text on the dark scrim chip.
  final bool onScrim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = onScrim
        ? AppColors.of(context).onPreviewSurface
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat.Hm().format(message.timestamp),
          style: theme.textTheme.labelSmall?.copyWith(color: muted),
        ),
        if (message.isOutgoing) ...[
          const SizedBox(width: AppSpacing.xs),
          StatusTick(
            status: message.status,
            neutralColor: onScrim ? muted : null,
          ),
        ],
      ],
    );
  }
}

/// Delivery status icon with a semantic label.
class StatusTick extends StatelessWidget {
  const StatusTick({super.key, required this.status, this.neutralColor});
  final MessageStatus status;

  /// Overrides the colour of the neutral states (over a dark scrim).
  final Color? neutralColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final neutral = neutralColor ?? scheme.onSurfaceVariant;
    final (icon, label, color) = switch (status) {
      MessageStatus.sending => (Icons.schedule, 'Sending', neutral),
      MessageStatus.sent => (Icons.done, 'Sent', neutral),
      MessageStatus.delivered => (Icons.done_all, 'Delivered', neutral),
      MessageStatus.read => (Icons.done_all, 'Read', scheme.primary),
      MessageStatus.failed => (Icons.error_outline, 'Failed', scheme.error),
    };
    return Semantics(
      label: label,
      child: Icon(icon, size: 16, color: color),
    );
  }
}

/// Starts a reply when dragged right by [swipeReplyDistance].
class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    required this.enabled,
    required this.onReply,
    required this.child,
  });
  final bool enabled;
  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply> {
  double _dx = 0;

  void _reset() {
    if (_dx != 0) setState(() => _dx = 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dx = (_dx + details.delta.dx).clamp(0.0, swipeReplyDistance + 16);
        });
      },
      onHorizontalDragEnd: (_) {
        final triggered = _dx >= swipeReplyDistance;
        _reset();
        if (triggered) {
          HapticFeedback.selectionClick();
          widget.onReply();
        }
      },
      onHorizontalDragCancel: _reset,
      child: Transform.translate(offset: Offset(_dx, 0), child: widget.child),
    );
  }
}
