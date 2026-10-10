import '../entities/chat_message.dart';

import 'message_copy_formatter.dart';

enum MessageAction { reply, copy, forward, share, open, info, delete }

/// Actions valid for a selection, in display order. [fileAvailable] says
/// whether a file or voice message still exists on this device; Share and
/// Open need it.
List<MessageAction> availableMessageActions(
  List<ChatMessage> selected, {
  required bool Function(ChatMessage message) fileAvailable,
}) {
  if (selected.isEmpty) return const <MessageAction>[];
  final single = selected.length == 1 ? selected.single : null;
  final isAttachment = single != null && single.type != MessageType.text;
  return <MessageAction>[
    if (single != null) MessageAction.reply,
    if (selected.any(isCopyable)) MessageAction.copy,
    MessageAction.forward,
    if (isAttachment && fileAvailable(single)) MessageAction.share,
    if (single != null &&
        single.type == MessageType.file &&
        fileAvailable(single))
      MessageAction.open,
    if (single != null) MessageAction.info,
    MessageAction.delete,
  ];
}
