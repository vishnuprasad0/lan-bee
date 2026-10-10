import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/services/file_format.dart';

String _statusLabel(MessageStatus status) {
  switch (status) {
    case MessageStatus.sending:
      return 'Sending';
    case MessageStatus.sent:
      return 'Sent';
    case MessageStatus.delivered:
      return 'Delivered';
    case MessageStatus.read:
      return 'Read';
    case MessageStatus.failed:
      return 'Failed';
  }
}

/// Bottom sheet with the full time, status, size, and file name.
Future<void> showMessageInfoSheet(BuildContext context, ChatMessage message) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final rows = <(String, String)>[
        (
          message.isOutgoing ? 'Sent' : 'Received',
          DateFormat('d MMM yyyy, HH:mm:ss').format(message.timestamp),
        ),
        ('Status', _statusLabel(message.status)),
        if (message.fileName != null) ('File name', message.fileName!),
        if (message.fileSize != null)
          ('Size', formatFileSize(message.fileSize!)),
        if (message.type == MessageType.voice && message.duration != null)
          ('Duration', formatDuration(message.duration!)),
      ];
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Message info', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
