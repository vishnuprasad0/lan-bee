import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/peer.dart';
import '../../domain/services/chat_timeline.dart';
import '../../domain/services/message_actions.dart';
import '../../domain/services/message_copy_formatter.dart';
import '../../domain/services/quoted_text.dart';
import '../../domain/use_cases/forward_messages.dart';
import '../../domain/use_cases/send_chat_to_peer.dart';
import '../../domain/use_cases/send_file_to_peer.dart';
import '../../domain/use_cases/send_voice_message_to_peer.dart';
import '../bloc/chat/chat_cubit.dart';
import '../bloc/chat/chat_state.dart';
import '../bloc/peers/peer_presence.dart';
import '../bloc/peers/peers_cubit.dart';
import '../bloc/read_state/read_state_cubit.dart';
import '../bloc/voice_playback/voice_playback_cubit.dart';
import '../services/attachment_picker.dart';
import '../services/chat_sender.dart';
import '../services/file_actions.dart';
import '../services/voice_recorder_controller.dart';
import '../widgets/chat/chat_app_bar.dart';
import '../widgets/chat/composer.dart';
import '../widgets/chat/date_separator.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/message_info_sheet.dart';
import '../widgets/chat/offline_banner.dart';
import '../widgets/chat/reply_bar.dart';
import '../widgets/chat/selection_app_bar.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/users/peer_info_dialog.dart';

import 'forward_picker_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.peer, super.key});
  final Peer peer;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final Set<String> _selected = <String>{};
  late final ChatSender _sender;
  StreamSubscription<ChatState>? _chatSub;
  ChatMessage? _replyTo;

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _sender = ChatSender(
      sendChat: context.read<SendChatToPeer>(),
      sendFile: context.read<SendFileToPeer>(),
      sendVoice: context.read<SendVoiceMessageToPeer>(),
      chat: context.read<ChatCubit>(),
    );
    _markRead();

    // New messages that arrive while this page is open count as read.
    _chatSub = context.read<ChatCubit>().stream.listen((_) {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle == null || lifecycle == AppLifecycleState.resumed) {
        _markRead();
      }
    });
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The conversation is on screen, so everything in it counts as read.
  void _markRead() {
    final last = context.read<ChatCubit>().getLastMessageForPeer(
      widget.peer.id,
    );
    context.read<ReadStateCubit>().markRead(
      widget.peer.id,
      upTo: last?.timestamp,
    );
  }

  PeerPresence _presence() {
    for (final p in context.read<PeersCubit>().state.peers) {
      if (p.peer.id == widget.peer.id) return p;
    }
    return PeerPresence(peer: widget.peer, isOnline: false, lastSeen: null);
  }

  Peer get _peer => _presence().peer;
  void _scrollToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // Sending
  void _sendText(String text) {
    final reply = _replyTo;
    final wire = reply == null
        ? text
        : QuotedText.compose(quoted: _snippetOf(reply), reply: text);
    setState(() => _replyTo = null);
    unawaited(_sender.sendText(_peer, wire));
    _scrollToLatest();
  }

  Future<void> _attach() async {
    try {
      final picked = await pickAttachment();
      if (picked == null || !mounted) return;
      unawaited(
        _sender.sendFile(
          _peer,
          name: picked.name,
          bytes: picked.bytes,
          size: picked.size,
          path: picked.path,
        ),
      );
      _scrollToLatest();
    } on Object {
      if (mounted) _toast('Failed to read file bytes');
    }
  }

  Future<void> _sendVoice(RecordedVoice voice) async {
    final bytes = await voice.file.readAsBytes();
    if (!mounted) return;
    final segments = voice.file.uri.pathSegments;
    unawaited(
      _sender.sendVoice(
        _peer,
        name: segments.isNotEmpty ? segments.last : 'voice.aac',
        bytes: bytes,
        path: voice.file.path,
        duration: voice.duration,
      ),
    );
    _scrollToLatest();
  }

  // Reply
  String _snippetOf(ChatMessage message) {
    switch (message.type) {
      case MessageType.file:
        return 'File: ${message.fileName ?? 'file'}';
      case MessageType.voice:
        return 'Voice message';
      case MessageType.text:
        final parsed = QuotedText.parse(message.text);
        return parsed.body.isNotEmpty ? parsed.body : (parsed.quote ?? '');
    }
  }

  void _startReply(ChatMessage message) {
    setState(() {
      _replyTo = message;
      _selected.clear();
    });
    _focus.requestFocus();
  }

  // Selection
  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _select(String id) {
    setState(() => _selected.add(id));
  }

  void _clearSelection() => setState(_selected.clear);
  Future<void> _onAction(
    MessageAction action,
    List<ChatMessage> selected,
  ) async {
    switch (action) {
      case MessageAction.reply:
        _startReply(selected.single);
      case MessageAction.copy:
        final name = _peer.displayName;
        await Clipboard.setData(
          ClipboardData(
            text: formatMessagesForCopy(
              selected,
              nameFor: (m) => m.isOutgoing ? 'You' : name,
            ),
          ),
        );
        if (!mounted) return;
        _clearSelection();
        _toast('Copied');
      case MessageAction.forward:
        await _forward(selected);
      case MessageAction.share:
        final m = selected.single;
        await shareLocalFile(context, m.filePath, name: m.fileName);
      case MessageAction.open:
        await openLocalFile(context, selected.single.filePath);
      case MessageAction.info:
        await showMessageInfoSheet(context, selected.single);
        if (mounted) _clearSelection();
      case MessageAction.delete:
        await _confirmDelete(selected);
    }
  }

  Future<void> _forward(List<ChatMessage> selected) async {
    final result = await Navigator.of(context).push<ForwardResult>(
      MaterialPageRoute(builder: (_) => ForwardPickerPage(messages: selected)),
    );
    if (result == null || !mounted) return;
    _clearSelection();
    final chats = result.chatCount;
    final skipped = result.skippedCount;
    _toast(
      'Forwarded to $chats ${chats == 1 ? 'chat' : 'chats'}'
      '${skipped > 0 ? '. $skipped ${skipped == 1 ? 'file' : 'files'} skipped' : ''}',
    );
  }

  Future<void> _confirmDelete(List<ChatMessage> selected) async {
    final count = selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete $count ${count == 1 ? 'message' : 'messages'} for you?',
        ),
        content: const Text('They stay on the other device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ids = {for (final m in selected) m.id};
    unawaited(context.read<VoicePlaybackCubit>().stopIfPlaying(ids));
    context.read<ChatCubit>().deleteMessages(ids);
    _clearSelection();
  }

  // Menu
  Future<void> _onMenu(ChatMenuAction action) async {
    switch (action) {
      case ChatMenuAction.peerInfo:
        await showPeerInfoDialog(context, _presence());
      case ChatMenuAction.clearChat:
        final chat = context.read<ChatCubit>();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Clear chat with ${widget.peer.displayName}?'),
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
        if (confirmed == true) chat.clearMessagesForPeer(widget.peer.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatCubit>();
    final presence = context.select<PeersCubit, PeerPresence>((cubit) {
      for (final p in cubit.state.peers) {
        if (p.peer.id == widget.peer.id) return p;
      }
      return PeerPresence(peer: widget.peer, isOnline: false, lastSeen: null);
    });
    final messages = chat.getMessagesForPeer(widget.peer.id);
    final selectedMessages = [
      for (final m in messages)
        if (_selected.contains(m.id)) m,
    ];
    final name = presence.peer.displayName;
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _selecting
            ? SelectionAppBar(
                count: selectedMessages.length,
                actions: availableMessageActions(
                  selectedMessages,
                  fileAvailable: (m) => localFileExists(m.filePath),
                ),
                onClose: _clearSelection,
                onAction: (action) => _onAction(action, selectedMessages),
              )
            : ChatAppBar(presence: presence, onMenuAction: _onMenu),
        body: Column(
          children: [
            if (!presence.isOnline) OfflineBanner(name: name),
            Expanded(child: _buildList(messages, name)),
            if (_replyTo case final reply?)
              ReplyBar(
                name: reply.isOutgoing ? 'yourself' : name,
                snippet: _snippetOf(reply),
                onClose: () => setState(() => _replyTo = null),
              ),
            Composer(
              focusNode: _focus,
              onSendText: _sendText,
              onAttach: _attach,
              onSendVoice: _sendVoice,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ChatMessage> messages, String name) {
    if (messages.isEmpty) {
      return EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        body: 'Say hi to $name.',
      );
    }
    final entries = buildTimeline(messages);
    final now = DateTime.now();
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[entries.length - 1 - index];
        switch (entry) {
          case DaySeparatorEntry():
            return DateSeparator(day: entry.day, now: now);
          case MessageEntry():
            final message = entry.message;
            return MessageBubble(
              key: ValueKey(message.id),
              entry: entry,
              selected: _selected.contains(message.id),
              selectionMode: _selecting,
              onTap: () => _toggle(message.id),
              onLongPress: () =>
                  _selecting ? _toggle(message.id) : _select(message.id),
              onSwipeReply: () => _startReply(message),
            );
        }
      },
    );
  }
}
