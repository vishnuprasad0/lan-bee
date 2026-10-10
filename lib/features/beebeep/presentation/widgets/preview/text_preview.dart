import 'package:flutter/material.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import 'package:beebeep/app/theme/app_text.dart';
import '../../services/text_preview_loader.dart';

/// Monospace, selectable text with horizontal and vertical scroll. Reads at
/// most [limitBytes] of the file, off the UI isolate.
class TextPreview extends StatefulWidget {
  const TextPreview({
    super.key,
    required this.path,
    required this.fallback,
    this.limitBytes = defaultTextPreviewBytes,
  });
  final String path;
  final Widget fallback;
  final int limitBytes;
  @override
  State<TextPreview> createState() => _TextPreviewState();
}

class _TextPreviewState extends State<TextPreview> {
  late final Future<TextPreviewData> _data = loadTextPreview(
    widget.path,
    limitBytes: widget.limitBytes,
  );
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TextPreviewData>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) return widget.fallback;
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final theme = Theme.of(context);
        return Column(
          children: [
            if (data.truncated) _TruncationBanner(limit: widget.limitBytes),
            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: SelectableText(
                      data.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: AppText.monospaceFamily,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TruncationBanner extends StatelessWidget {
  const _TruncationBanner({required this.limit});
  final int limit;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final String label;
    if (limit % (1024 * 1024) == 0) {
      label = '${limit ~/ (1024 * 1024)} MB';
    } else if (limit % 1024 == 0) {
      label = '${limit ~/ 1024} KB';
    } else {
      label = '$limit bytes';
    }
    return Container(
      width: double.infinity,
      color: scheme.primaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        'Showing the first $label',
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
