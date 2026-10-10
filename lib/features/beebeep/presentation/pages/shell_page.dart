import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:beebeep/app/app_info.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../domain/entities/peer.dart';
import '../../domain/use_cases/update_discovery_name.dart';
import '../bloc/chat/chat_cubit.dart';
import '../bloc/conversations/conversation_summaries.dart';
import '../bloc/logs/logs_cubit.dart';
import '../bloc/peers/peers_cubit.dart';
import '../bloc/read_state/read_state_cubit.dart';
import '../widgets/common/chat_pane_scope.dart';
import '../widgets/common/edit_name_dialog.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/network_chip.dart';
import 'chat_page.dart';
import 'chats_tab.dart';
import 'files_tab.dart';
import 'settings_tab.dart';
import 'users_tab.dart';

/// App shell: app bar with the network chip and four tabs. Narrow windows
/// get a bottom NavigationBar; wide ones a side rail, with the open chat
/// beside the Chats and Users lists.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, this.askForName = false});

  /// No name was found on this device: ask for one after the first frame.
  final bool askForName;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  static const int _usersIndex = 1;

  /// Keeps tab state when the layout switches between narrow and wide.
  final _tabsKey = GlobalKey();

  int _index = 0;

  /// Chat shown beside the list in the wide layout.
  Peer? _openPeer;

  /// Bumped when the first-run prompt saves a name, so Settings reloads it.
  int _nameVersion = 0;

  @override
  void initState() {
    super.initState();
    context.read<PeersCubit>().start();
    context.read<LogsCubit>().start();
    if (widget.askForName) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askForName());
    }
  }

  Future<void> _askForName() async {
    if (!mounted) return;
    final update = context.read<UpdateDiscoveryName>();
    final name = await showEditNameDialog(
      context,
      initial: '',
      title: 'What should people call you?',
      message:
          'Your name is shown to people on your network. '
          'You can change it later in Settings.',
      cancelLabel: 'Later',
      dismissible: false,
    );
    if (name == null) return;
    await update(name);
    if (mounted) setState(() => _nameVersion++);
  }

  void _select(int index) => setState(() => _index = index);

  void _openInPane(Peer peer) => setState(() => _openPeer = peer);

  @override
  Widget build(BuildContext context) {
    final peersState = context.watch<PeersCubit>().state;
    final unread = totalUnread(
      conversationSummariesOf(
        peers: peersState,
        chat: context.watch<ChatCubit>().state,
        read: context.watch<ReadStateCubit>().state,
      ),
    );
    final destinations = _destinations(unread);
    final tabs = KeyedSubtree(
      key: _tabsKey,
      child: IndexedStack(
        index: _index,
        children: [
          ChatsTab(onGoToUsers: () => _select(_usersIndex)),
          const UsersTab(),
          const FilesTab(),
          SettingsTab(key: ValueKey(_nameVersion)),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= AppSizes.wideLayout;
        return Scaffold(
          appBar: AppBar(
            title: const Text(AppInfo.name),
            actions: [
              NetworkChip(status: NetworkStatus.fromPeers(peersState)),
              const SizedBox(width: AppSpacing.lg),
            ],
          ),
          body: Column(
            children: [
              if (peersState.errorMessage != null)
                _ErrorBanner(message: peersState.errorMessage!),
              Expanded(
                child: wide
                    ? _wideBody(tabs, destinations, width: width)
                    : tabs,
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: [
                    for (final d in destinations)
                      NavigationDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: d.label,
                        tooltip: d.tooltip,
                      ),
                  ],
                ),
        );
      },
    );
  }

  /// Side rail, then either the list with the open chat beside it (Chats,
  /// Users) or one centred column (Files, Settings).
  Widget _wideBody(
    Widget tabs,
    List<_Destination> destinations, {
    required double width,
  }) {
    final extended = width >= AppSizes.extendedRail;
    final showsChat = _index <= _usersIndex;
    final Widget content;
    if (showsChat) {
      content = Row(
        children: [
          SizedBox(
            width: AppSizes.listPane,
            child: ChatPaneScope(
              openPeerId: _openPeer?.id,
              onOpen: _openInPane,
              child: tabs,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _ChatPane(peer: _openPeer)),
        ],
      );
    } else {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: tabs,
        ),
      );
    }
    return Row(
      children: [
        NavigationRail(
          selectedIndex: _index,
          onDestinationSelected: _select,
          extended: extended,
          labelType: extended ? null : NavigationRailLabelType.all,
          destinations: [
            for (final d in destinations)
              NavigationRailDestination(
                icon: Tooltip(message: d.tooltip, child: d.icon),
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              ),
          ],
        ),
        const VerticalDivider(width: 1),
        Expanded(child: content),
      ],
    );
  }

  List<_Destination> _destinations(int unread) {
    Widget chatsIcon(IconData icon) => Badge(
      isLabelVisible: unread > 0,
      label: Text(unread > 99 ? '99+' : '$unread'),
      child: Icon(icon),
    );
    return [
      _Destination(
        icon: chatsIcon(Icons.chat_bubble_outline),
        selectedIcon: chatsIcon(Icons.chat_bubble),
        label: 'Chats',
        tooltip: unread > 0 ? 'Chats, $unread unread' : 'Chats',
      ),
      const _Destination(
        icon: Icon(Icons.group_outlined),
        selectedIcon: Icon(Icons.group),
        label: 'Users',
      ),
      const _Destination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: 'Files',
      ),
      const _Destination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
  }
}

/// One shell tab, shown in the bottom bar or the side rail.
class _Destination {
  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    String? tooltip,
  }) : tooltip = tooltip ?? label;

  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final String tooltip;
}

/// Right side of the wide layout: the open chat, or a hint to pick one.
class _ChatPane extends StatelessWidget {
  const _ChatPane({required this.peer});

  final Peer? peer;

  @override
  Widget build(BuildContext context) {
    final peer = this.peer;
    if (peer == null) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'No chat open',
        body: 'Pick a chat or a person on the left.',
      );
    }
    return ChatPage(key: ValueKey(peer.id), peer: peer);
  }
}

/// Shown when discovery reports an error (usually Wi-Fi is off or blocked).
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: scheme.onErrorContainer),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Network problem. Check your Wi-Fi. $message',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: () => context.read<PeersCubit>().restart(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
