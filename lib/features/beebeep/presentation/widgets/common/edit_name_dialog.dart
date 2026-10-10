import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_spacing.dart';

/// Asks for the name shown to others. Returns the trimmed name, or null when
/// the user cancels or leaves it empty.
Future<String?> showEditNameDialog(
  BuildContext context, {
  required String initial,
  String title = 'Display name',
  String? message,
  String cancelLabel = 'Cancel',
  bool dismissible = true,
}) async {
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: dismissible,
    builder: (_) => _EditNameDialog(
      initial: initial,
      title: title,
      message: message,
      cancelLabel: cancelLabel,
    ),
  );
  final value = result?.trim() ?? '';
  return value.isEmpty ? null : value;
}

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({
    required this.initial,
    required this.title,
    required this.message,
    required this.cancelLabel,
  });

  final String initial;
  final String title;
  final String? message;
  final String cancelLabel;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message != null) ...[
            Text(message),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Name shown to others'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
