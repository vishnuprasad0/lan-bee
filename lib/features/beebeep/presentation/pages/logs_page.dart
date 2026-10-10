import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:beebeep/app/theme/app_spacing.dart';
import '../bloc/logs/logs_cubit.dart';
import '../bloc/logs/logs_state.dart';
import '../widgets/common/empty_state.dart';

/// Displays connection and transfer logs.
class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  Future<void> _copyAll(BuildContext context, List<String> lines) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    messenger.showSnackBar(const SnackBar(content: Text('Copied')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection log'),
        actions: [
          BlocBuilder<LogsCubit, LogsState>(
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.copy_all_outlined),
              tooltip: 'Copy all',
              onPressed: state.lines.isEmpty
                  ? null
                  : () => _copyAll(context, state.lines),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: theme.colorScheme.surfaceContainer,
            child: Text(
              'Includes discovery, connections, encryption, and transfers.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: BlocBuilder<LogsCubit, LogsState>(
              builder: (context, state) {
                if (state.lines.isEmpty) {
                  return const EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No log lines yet',
                  );
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: state.lines.length,
                  itemBuilder: (context, index) {
                    final line = state.lines[state.lines.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
