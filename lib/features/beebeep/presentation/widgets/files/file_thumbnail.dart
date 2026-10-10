import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:beebeep/app/theme/app_colors.dart';
import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import '../../../domain/services/preview_kind.dart';

/// Rounded square thumbnail of an image or SVG file for list rows.
class FileThumbnail extends StatelessWidget {
  const FileThumbnail({super.key, required this.path, required this.kind});
  final String path;
  final PreviewKind kind;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final Widget broken = ColoredBox(
      color: scheme.surfaceContainer,
      child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
    );
    return ClipRRect(
      borderRadius: AppRadii.cardRadius,
      child: SizedBox(
        width: AppSizes.listThumb,
        height: AppSizes.listThumb,
        child: kind == PreviewKind.svg
            ? ColoredBox(
                color: colors.svgSurface,
                child: SvgPicture.file(File(path), fit: BoxFit.contain),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
                cacheWidth: AppSizes.listThumbCacheWidth,
                errorBuilder: (context, error, stack) => broken,
              ),
      ),
    );
  }
}
