import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:beebeep/app/theme/app_spacing.dart';
import '../bloc/peers/peer_presence.dart';
import '../bloc/peers/peers_cubit.dart';
import '../bloc/peers/peers_state.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/open_chat.dart';
import '../widgets/users/peer_info_dialog.dart';
import '../widgets/users/peer_tile.dart';
import '../widgets/users/searching_empty_state.dart';

/// Every discovered or cached peer, split into Online and Offline sections.
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => context.read<PeersCubit>().restart();

  List<PeerPresence> _filter(List<PeerPresence> peers) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return peers;
    return peers
        .where((p) => p.peer.displayName.toLowerCase().contains(query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeersCubit, PeersState>(
      builder: (context, state) {
        final hasPeers = state.peers.isNotEmpty;
        return Column(
          children: [
            if (hasPeers)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search people',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: _buildBody(context, state),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PeersState state) {
    if (state.peers.isEmpty) {
      return _scrollableCenter(
        SearchingEmptyState(
          isSearching: state.isDiscovering,
          errorMessage: state.errorMessage,
          onRetry: _refresh,
        ),
      );
    }

    final filtered = _filter(state.peers);
    if (filtered.isEmpty) {
      return _scrollableCenter(
        EmptyState(
          icon: Icons.search_off,
          title: 'No matches',
          body: 'No one called "${_query.trim()}".',
        ),
      );
    }

    final online = filtered.where((p) => p.isOnline).toList(growable: false);
    final offline = filtered.where((p) => !p.isOnline).toList(growable: false);
    final now = DateTime.now();

    final children = <Widget>[
      if (online.isNotEmpty) ...[
        _SectionHeader('Online (${online.length})'),
        for (final presence in online) _tile(context, presence, now),
      ],
      if (offline.isNotEmpty) ...[
        _SectionHeader('Offline (${offline.length})'),
        for (final presence in offline) _tile(context, presence, now),
      ],
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _tile(BuildContext context, PeerPresence presence, DateTime now) {
    return PeerTile(
      key: ValueKey(presence.peer.id),
      presence: presence,
      now: now,
      onTap: () => openChat(context, presence.peer),
      onInfo: () => showPeerInfoDialog(context, presence),
    );
  }

  /// Keeps pull-to-refresh working when there is nothing to scroll.
  Widget _scrollableCenter(Widget child) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
