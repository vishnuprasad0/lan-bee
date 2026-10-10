import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../bloc/peers/peers_state.dart';
import 'status_dot.dart';

enum NetworkStatus {
  /// Discovery is running and at least one peer is reachable.
  online,

  /// Discovery is running but nobody has been found yet.
  searching,

  /// Discovery is stopped or failed.
  offline;

  String get label => switch (this) {
    NetworkStatus.online => 'Online',
    NetworkStatus.searching => 'Searching...',
    NetworkStatus.offline => 'Offline',
  };

  /// Derived only from what discovery reports; nothing is guessed.
  static NetworkStatus fromPeers(PeersState state) {
    if (state.errorMessage != null || !state.isDiscovering) {
      return NetworkStatus.offline;
    }
    return state.peers.any((p) => p.isOnline)
        ? NetworkStatus.online
        : NetworkStatus.searching;
  }
}

/// App bar chip showing the discovery/network state.
class NetworkChip extends StatelessWidget {
  const NetworkChip({super.key, required this.status});

  final NetworkStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final Widget indicator = switch (status) {
      NetworkStatus.online => const StatusDot(isOnline: true),
      NetworkStatus.offline => const StatusDot(isOnline: false),
      NetworkStatus.searching =>
        reduceMotion
            ? Icon(Icons.sync, size: 14, color: theme.colorScheme.primary)
            : const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
    };

    return Semantics(
      label: 'Network: ${status.label}',
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: AppRadii.chipRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              indicator,
              const SizedBox(width: AppSpacing.sm),
              Text(
                status.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
