import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:beebeep/app/theme/app_colors.dart';
import 'zoom_viewer.dart';

/// Decode width cap so a huge photo does not exhaust memory; zoom stays sharp
/// well beyond screen resolution.
const int _previewDecodeWidth = 3000;

/// Raster image on a near-black surface with pinch and double-tap zoom.
class ImagePreview extends StatelessWidget {
  const ImagePreview({
    super.key,
    required this.path,
    required this.heroTag,
    required this.fallback,
  });
  final String path;
  final String heroTag;
  final Widget fallback;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ColoredBox(
      color: colors.previewSurface,
      child: ZoomViewer(
        child: Hero(
          tag: heroTag,
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            cacheWidth: _previewDecodeWidth,
            errorBuilder: (context, error, stack) => fallback,
          ),
        ),
      ),
    );
  }
}

/// SVG on a light surface (SVGs often have transparent backgrounds).
class SvgPreview extends StatelessWidget {
  const SvgPreview({
    super.key,
    required this.path,
    required this.heroTag,
    required this.fallback,
  });
  final String path;
  final String heroTag;
  final Widget fallback;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ColoredBox(
      color: colors.svgSurface,
      child: ZoomViewer(
        child: Hero(
          tag: heroTag,
          child: SvgPicture.file(
            File(path),
            fit: BoxFit.contain,
            placeholderBuilder: (context) => fallback,
            errorBuilder: (context, error, stack) => fallback,
          ),
        ),
      ),
    );
  }
}
