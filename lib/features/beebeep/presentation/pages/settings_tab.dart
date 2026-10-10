import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:beebeep/app/app_info.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../domain/use_cases/load_discovery_name.dart';
import '../../domain/use_cases/update_discovery_name.dart';
import '../bloc/chat/chat_cubit.dart';
import '../bloc/peers/peers_cubit.dart';
import '../bloc/peers/peers_state.dart';
import '../widgets/common/edit_name_dialog.dart';
import '../widgets/common/peer_avatar.dart';
import 'logs_page.dart';

/// Settings grouped into Profile, Network, Storage, Diagnostics, and About.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, this.fallbackName = AppInfo.name});

  /// Shown until a name is saved (only when no name could be suggested and
  /// the first-run prompt was skipped).
  final String fallbackName;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final loader = context.read<LoadDiscoveryName>();
    final name = await loader(fallback: widget.fallbackName);
    if (!mounted) return;
    setState(() => _displayName = name);
  }

  Future<void> _editName() async {
    final updater = context.read<UpdateDiscoveryName>();
    final messenger = ScaffoldMessenger.of(context);
    final value = await showEditNameDialog(
      context,
      initial: _displayName ?? '',
    );
    if (value == null || value == _displayName) return;

    await updater(value);
    if (!mounted) return;
    setState(() => _displayName = value);
    messenger.showSnackBar(const SnackBar(content: Text('Name updated')));
  }

  Future<void> _confirmClearHistory() async {
    final chatCubit = context.read<ChatCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all chat history?'),
        content: const Text(
          'Every conversation is removed from this device. '
          'Messages stay on the other devices.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Clear all',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    chatCubit.clearMessages();
    messenger.showSnackBar(
      const SnackBar(content: Text('Chat history cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = _displayName ?? widget.fallbackName;

    return ListView(
      children: [
        const _SectionTitle('Profile'),
        ListTile(
          minVerticalPadding: AppSpacing.sm,
          leading: PeerAvatar(
            peerId: 'self',
            name: name,
            size: AppSizes.avatarList,
          ),
          title: Text(name),
          subtitle: const Text('Shown to people on your network'),
          trailing: const Icon(Icons.edit_outlined),
          onTap: _displayName == null ? null : _editName,
        ),
        const _SectionTitle('Network'),
        BlocBuilder<PeersCubit, PeersState>(
          buildWhen: (a, b) => a.isDiscovering != b.isDiscovering,
          builder: (context, state) {
            return SwitchListTile(
              secondary: const Icon(Icons.wifi_find),
              title: const Text('Discovery'),
              subtitle: Text(
                state.isDiscovering
                    ? 'Looking for people on this network'
                    : 'Off. Turn on to find people.',
              ),
              value: state.isDiscovering,
              onChanged: (on) {
                final cubit = context.read<PeersCubit>();
                if (on) {
                  cubit.start();
                } else {
                  cubit.stop();
                }
              },
            );
          },
        ),
        const _SectionTitle('Storage'),
        ListTile(
          leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          title: const Text('Clear all chat history'),
          subtitle: const Text('Removes conversations from this device'),
          onTap: _confirmClearHistory,
        ),
        const _SectionTitle('Diagnostics'),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Connection log'),
          subtitle: const Text('Discovery, connections, and transfers'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const LogsPage()),
          ),
        ),
        const _SectionTitle('About'),
        const ListTile(
          leading: Icon(Icons.info_outline),
          title: Text(AppInfo.name),
          subtitle: Text('Version ${AppInfo.version}'),
        ),
        const ListTile(
          leading: Icon(Icons.hub_outlined),
          title: Text(AppInfo.compatibilityNote),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: const Text('Open-source licences'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
            context: context,
            applicationName: AppInfo.name,
            applicationVersion: AppInfo.version,
          ),
        ),
        const ListTile(
          enabled: false,
          leading: Icon(Icons.privacy_tip_outlined),
          title: Text('Privacy policy (coming soon)'),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
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
