import 'package:flutter/material.dart';
import 'package:beebeep/app/theme/app_sizes.dart';

/// Pinch zoom and double-tap zoom in/out around [child].
class ZoomViewer extends StatefulWidget {
  const ZoomViewer({super.key, required this.child});
  final Widget child;
  @override
  State<ZoomViewer> createState() => _ZoomViewerState();
}

class _ZoomViewerState extends State<ZoomViewer> {
  final TransformationController _controller = TransformationController();
  Offset _doubleTapAt = Offset.zero;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomedIn = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (zoomedIn) {
      _controller.value = Matrix4.identity();
      return;
    }
    const scale = AppSizes.previewDoubleTapZoom;
    final dx = -_doubleTapAt.dx * (scale - 1);
    final dy = -_doubleTapAt.dy * (scale - 1);
    _controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) => _doubleTapAt = details.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _controller,
        maxScale: AppSizes.previewMaxZoom,
        child: SizedBox.expand(child: Center(child: widget.child)),
      ),
    );
  }
}
