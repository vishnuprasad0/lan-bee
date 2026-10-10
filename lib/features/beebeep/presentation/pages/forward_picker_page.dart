import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:beebeep/app/theme/app_spacing.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/peer.dart';
import '../../domain/use_cases/forward_messages.dart';
import '../bloc/chat/chat_cubit.dart';
import '../bloc/peers/peer_presence.dart';
import '../bloc/peers/peers_cubit.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/peer_avatar.dart';

/// Pick the chats to forward [messages] to. Pops with a [ForwardResult] after
/// sending, or null when the user backs out.
class ForwardPickerPage extends StatefulWidget {
  const ForwardPickerPage({super.key, required this.messages});
  final List<ChatMessage> messages;

  @override
  State<ForwardPickerPage> createState() => _ForwardPickerPageState();
}

class _ForwardPickerPageState extends State<ForwardPickerPage> {
  final Set<String> _chosen = <String>{};
  String _query = '';
  bool _sending = false;
  List<PeerPresence> _visiblePeers(List<PeerPresence> all) {
    final needle = _query.trim().toLowerCase();
    final filtered = all
        .where(
          (p) =>
              needle.isEmpty ||
              p.peer.displayName.toLowerCase().contains(needle),
        )
        .toList();
    filtered.sort((a, b) {
      if (a.isOnline != b.isOnline) return a.isOnline ? -1 : 1;
      return a.peer.displayName.toLowerCase().compareTo(
        b.peer.displayName.toLowerCase(),
      );
    });
    return filtered;
  }

  Future<void> _send(List<PeerPresence> all) async {
    final targets = <Peer>[
      for (final p in all)
        if (_chosen.contains(p.peer.id)) p.peer,
    ];
    if (targets.isEmpty) return;
    setState(() => _sending = true);
    final forward = context.read<ForwardMessages>();
    final chat = context.read<ChatCubit>();
    final navigator = Navigator.of(context);
    final result = await forward(messages: widget.messages, targets: targets);
    chat.addMessages(result.sent);
    if (navigator.mounted) navigator.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = context.watch<PeersCubit>().state.peers;
    final visible = _visiblePeers(all);
    return Scaffold(
      appBar: AppBar(title: const Text('Forward to...')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search people',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const EmptyState(
                    icon: Icons.group_outlined,
                    title: 'No one to forward to',
                    body: 'People on the same Wi-Fi show up here.',
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final presence = visible[index];
                      final peer = presence.peer;
                      final name = peer.displayName.isEmpty
                          ? 'Unknown'
                          : peer.displayName;
                      return CheckboxListTile(
                        value: _chosen.contains(peer.id),
                        onChanged: _sending
                            ? null
                            : (checked) => setState(() {
                                if (checked ?? false) {
                                  _chosen.add(peer.id);
                                } else {
                                  _chosen.remove(peer.id);
                                }
                              }),
                        secondary: PeerAvatar(
                          peerId: peer.id,
                          name: name,
                          isOnline: presence.isOnline,
                        ),
                        title: Text(name),
                        subtitle: Text(
                          presence.isOnline ? 'Online' : 'Offline',
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _chosen.isEmpty || _sending
                      ? null
                      : () => _send(all),
                  icon: _sending
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _chosen.isEmpty ? 'Send' : 'Send (${_chosen.length})',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
