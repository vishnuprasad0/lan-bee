import 'dart:async';

import 'package:flutter/material.dart';

import '../common/empty_state.dart';

/// Users tab empty state. While discovery runs it shows a spinner; after
/// [hintDelay] (or at once when discovery is off) it shows the Wi-Fi hint
/// with a Retry action.
class SearchingEmptyState extends StatefulWidget {
  const SearchingEmptyState({
    super.key,
    required this.isSearching,
    required this.onRetry,
    this.errorMessage,
    this.hintDelay = const Duration(seconds: 10),
  });

  final bool isSearching;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Duration hintDelay;

  @override
  State<SearchingEmptyState> createState() => _SearchingEmptyStateState();
}

class _SearchingEmptyStateState extends State<SearchingEmptyState> {
  Timer? _timer;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(SearchingEmptyState oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSearching != widget.isSearching) _syncTimer();
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (!widget.isSearching) {
      _showHint = true;
      return;
    }
    _showHint = false;
    _timer = Timer(widget.hintDelay, () {
      if (mounted) setState(() => _showHint = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        title: 'Could not search the network',
        body: widget.errorMessage,
        actionLabel: 'Retry',
        onAction: widget.onRetry,
      );
    }

    if (_showHint) {
      return EmptyState(
        icon: Icons.wifi_find,
        title: 'No one found yet',
        body: 'Make sure you are on the same Wi-Fi as BeeBEEP desktop.',
        actionLabel: 'Retry',
        onAction: widget.onRetry,
      );
    }

    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return EmptyState(
      icon: Icons.wifi_find,
      leading: reduceMotion
          ? null
          : const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(),
            ),
      title: 'Looking for people on this network...',
    );
  }
}
