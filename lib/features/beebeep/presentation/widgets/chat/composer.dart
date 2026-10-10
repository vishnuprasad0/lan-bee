import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:beebeep/app/form_factor.dart';
import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../services/voice_recorder_controller.dart';

import 'recording_bar.dart';

/// Slide distance (px) that cancels a recording on release.
const double cancelRecordingDistance = 80;

/// Voice notes shorter than this are treated as accidental taps.
const Duration minVoiceDuration = Duration(milliseconds: 600);

/// Attach button, 1-5 line field, and a mic (empty) or send (text) button.
/// Hold the mic to record; release sends, slide left past 80 px cancels.
/// On desktop, Enter sends and Shift+Enter starts a new line.
class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.onSendText,
    required this.onAttach,
    required this.onSendVoice,
    this.focusNode,
  });
  final void Function(String text) onSendText;
  final VoidCallback onAttach;
  final void Function(RecordedVoice voice) onSendVoice;
  final FocusNode? focusNode;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _controller = TextEditingController();
  final _recorder = VoiceRecorderController();
  bool _pressActive = false;
  DateTime? _pressStartedAt;
  bool _permissionAsked = false;
  double _slide = 0;

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendText(text);
    _controller.clear();
  }

  Future<void> _startRecording() async {
    _pressActive = true;
    _pressStartedAt = DateTime.now();
    final messenger = ScaffoldMessenger.of(context);
    final bool started;
    try {
      started = await _recorder.start();
    } on Object catch (error) {
      _pressActive = false;
      debugPrint('Recorder start failed: $error');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not start recording')),
      );
      return;
    }
    if (!started) {
      _pressActive = false;
      _permissionAsked = true;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Allow microphone access to record voice messages'),
        ),
      );
      return;
    }
    if (!_pressActive) {
      // Released before the recorder was ready.
      await _recorder.stop(keep: false);
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _finishRecording() async {
    _pressActive = false;
    final cancel = _slide < -cancelRecordingDistance;
    if (mounted) setState(() => _slide = 0);
    final startedAt = _pressStartedAt;
    _pressStartedAt = null;
    final voice = await _recorder.stop(
      keep: !cancel,
      minDuration: minVoiceDuration,
    );
    if (voice != null) {
      widget.onSendVoice(voice);
      return;
    }
    final tooShort =
        startedAt != null &&
        DateTime.now().difference(startedAt) < minVoiceDuration;
    if (!cancel && tooShort && mounted && !_permissionAsked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hold to record, release to send')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_recorder, _controller]),
            builder: (context, _) {
              final recording = _recorder.isRecording;
              final hasText = _controller.text.trim().isNotEmpty;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!recording)
                    IconButton(
                      tooltip: 'Attach file',
                      constraints: const BoxConstraints(
                        minWidth: AppSizes.tapTarget,
                        minHeight: AppSizes.tapTarget,
                      ),
                      icon: const Icon(Icons.attach_file),
                      onPressed: widget.onAttach,
                    ),
                  Expanded(
                    child: recording
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: AppSizes.composerMin,
                            ),
                            child: RecordingBar(
                              elapsed: _recorder.elapsed,
                              slideOffset: _slide,
                            ),
                          )
                        : CallbackShortcuts(
                            bindings: {
                              if (isDesktopPlatform)
                                const SingleActivator(LogicalKeyboardKey.enter):
                                    _send,
                            },
                            child: TextField(
                              controller: _controller,
                              focusNode: widget.focusNode,
                              autofocus: isDesktopPlatform,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Message',
                                filled: true,
                                fillColor: theme.colorScheme.surfaceContainer,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: AppRadii.fieldRadius,
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (hasText && !recording)
                    _RoundButton(
                      tooltip: isDesktopPlatform ? 'Send (Enter)' : 'Send',
                      icon: Icons.send,
                      onPressed: _send,
                    )
                  else
                    _MicButton(
                      // Keeps the gesture alive while the row changes shape.
                      key: const ValueKey('mic'),
                      onStart: _startRecording,
                      onMove: (dx) => setState(() => _slide = dx),
                      onEnd: _finishRecording,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton.filled(
      tooltip: tooltip,
      constraints: const BoxConstraints(
        minWidth: AppSizes.tapTarget,
        minHeight: AppSizes.tapTarget,
      ),
      style: IconButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}

/// Hold-to-record mic. Uses raw pointer events so recording starts the
/// moment the finger touches the button: a GestureDetector long press waits
/// 500 ms, and an IconButton tooltip competes for the same long press and
/// wins, so recording never started.
class _MicButton extends StatefulWidget {
  const _MicButton({
    super.key,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
  });
  final VoidCallback onStart;
  final void Function(double dx) onMove;
  final VoidCallback onEnd;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  Offset? _origin;

  void _end() {
    if (_origin == null) return;
    _origin = null;
    widget.onEnd();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Record voice message. Hold to record, release to send.',
      button: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _origin = event.position;
          widget.onStart();
        },
        onPointerMove: (event) {
          final origin = _origin;
          if (origin == null) return;
          widget.onMove(event.position.dx - origin.dx);
        },
        onPointerUp: (_) => _end(),
        onPointerCancel: (_) => _end(),
        child: SizedBox.square(
          dimension: AppSizes.tapTarget,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mic, color: scheme.onPrimary),
          ),
        ),
      ),
    );
  }
}
