import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:beebeep/app/theme/app_colors.dart';
import 'package:beebeep/app/theme/app_radii.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'package:beebeep/app/theme/app_spacing.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/services/preview_kind.dart';
import '../common/open_preview.dart';

/// Image or SVG attachment shown as a rounded thumbnail inside a bubble. The
/// file name is hidden; [footer] (time and ticks) sits bottom-right on a
/// translucent scrim chip. Tap opens the preview, unless [onTapEnabled] is
/// false (selection mode, where taps toggle selection instead).
class ImageTile extends StatelessWidget {
  const ImageTile({
    super.key,
    required this.message,
    required this.footer,
    this.onTapEnabled = true,
  });
  final ChatMessage message;
  final Widget footer;
  final bool onTapEnabled;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = message.fileName ?? 'Image';
    final isSvg = previewKindFor(message.fileName) == PreviewKind.svg;
    final path = message.filePath!;
    final Widget picture = isSvg
        ? ColoredBox(
            color: colors.svgSurface,
            child: SizedBox(
              width: AppSizes.thumbMaxWidth,
              height: AppSizes.thumbMaxWidth * 0.75,
              child: SvgPicture.file(File(path), fit: BoxFit.contain),
            ),
          )
        : ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: AppSizes.thumbMinSide,
              minHeight: AppSizes.thumbMinSide,
              maxWidth: AppSizes.thumbMaxWidth,
              maxHeight: AppSizes.thumbMaxHeight,
            ),
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              cacheWidth: AppSizes.thumbCacheWidth,
              errorBuilder: (context, error, stack) => const SizedBox(
                width: AppSizes.thumbMaxWidth,
                height: AppSizes.thumbMaxWidth * 0.75,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          );
    return Semantics(
      button: onTapEnabled,
      label: 'Image $name. Tap to view.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTapEnabled ? () => openFilePreview(context, message) : null,
        child: ClipRRect(
          borderRadius: AppRadii.cardRadius,
          child: Stack(
            children: [
              Hero(tag: message.id, child: picture),
              Positioned(
                right: AppSpacing.xs + 2,
                bottom: AppSpacing.xs + 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.previewScrim,
                    borderRadius: AppRadii.chipRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    child: footer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
