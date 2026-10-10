import '../entities/chat_message.dart';

/// Removes messages from local history only (the other device keeps them).
/// Pure: returns the remaining list; the caller persists it through the
/// existing chat history path (`ChatCubit`).
class DeleteMessages {
  const DeleteMessages();
  List<ChatMessage> call(List<ChatMessage> all, Set<String> ids) {
    if (ids.isEmpty) return all;
    return all.where((m) => !ids.contains(m.id)).toList(growable: false);
  }
}
