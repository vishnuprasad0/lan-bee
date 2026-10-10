import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:beebeep/app/theme/app_spacing.dart';
import '../../domain/services/chat_timeline.dart';
import '../../domain/services/file_entries.dart';
import '../bloc/chat/chat_cubit.dart';
import '../bloc/peers/peers_cubit.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/files/file_row.dart';

String _filterLabel(FileFilter filter) {
  switch (filter) {
    case FileFilter.all:
      return 'All';
    case FileFilter.received:
      return 'Received';
    case FileFilter.sent:
      return 'Sent';
    case FileFilter.voice:
      return 'Voice';
  }
}

/// Files and voice notes derived from the chat history, both directions,
/// grouped by day with filter chips.
class FilesTab extends StatefulWidget {
  const FilesTab({super.key});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  FileFilter _filter = FileFilter.all;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ChatCubit>().state.messages;
    final peers = context.watch<PeersCubit>().state.peers;
    final names = <String, String>{
      for (final p in peers)
        if (p.peer.displayName.isNotEmpty) p.peer.id: p.peer.displayName,
    };

    final hasAnyFile = history.any(isFileEntry);
    if (!hasAnyFile) {
      return const EmptyState(
        icon: Icons.folder_outlined,
        title: 'No files yet',
        body: 'Files you send or receive appear here.',
      );
    }

    final groups = groupFileEntries(history, _filter);
    final now = DateTime.now();

    return Column(
      children: [
        _FilterChips(
          selected: _filter,
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        Expanded(
          child: groups.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_open_outlined,
                  title: 'Nothing here',
                  body: 'No files match this filter.',
                )
              : ListView(
                  children: [
                    for (final group in groups) ...[
                      FileDayHeader(
                        label: daySeparatorLabel(group.day, now: now),
                      ),
                      for (final message in group.items)
                        FileRow(
                          key: ValueKey(message.id),
                          message: message,
                          peerName: names[message.peerId] ?? 'Unknown',
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final FileFilter selected;
  final ValueChanged<FileFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final filter in FileFilter.values) ...[
            ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
