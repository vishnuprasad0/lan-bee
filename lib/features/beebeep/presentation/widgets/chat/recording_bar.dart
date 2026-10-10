import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/services/file_format.dart';

/// Replaces the text field while recording: pulsing dot in primary (no red),
/// timer, and the "Slide left to cancel" hint that follows the finger.
class RecordingBar extends StatefulWidget {
  const RecordingBar({
    super.key,
    required this.elapsed,
    required this.slideOffset,
  });
  final Duration elapsed;

  /// Horizontal drag of the mic button (0 or negative).
  final double slideOffset;

  @override
  State<RecordingBar> createState() => _RecordingBarState();
}

class _RecordingBarState extends State<RecordingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 1;
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      liveRegion: true,
      label:
          'Recording ${formatDuration(widget.elapsed)}. '
          'Release to send, slide left to cancel.',
      child: ExcludeSemantics(
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.md),
            FadeTransition(
              opacity: Tween<double>(begin: 0.3, end: 1).animate(_pulse),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 12, height: 12),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              formatDuration(widget.elapsed),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Expanded(
              child: Transform.translate(
                offset: Offset(widget.slideOffset.clamp(-80.0, 0.0), 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left, color: muted),
                    Flexible(
                      child: Text(
                        'Slide left to cancel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
