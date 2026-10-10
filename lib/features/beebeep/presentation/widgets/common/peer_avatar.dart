import 'package:flutter/material.dart';

import 'package:beebeep/app/theme/app_colors.dart';
import 'package:beebeep/app/theme/app_sizes.dart';
import 'status_dot.dart';

/// Initials avatar. The background is chosen from the avatar palette by a
/// stable hash of [peerId], so a peer keeps its colour across runs.
class PeerAvatar extends StatelessWidget {
  const PeerAvatar({
    super.key,
    required this.peerId,
    required this.name,
    this.size = AppSizes.avatarList,
    this.isOnline,
  });

  final String peerId;
  final String name;
  final double size;

  /// When non-null a status dot is drawn at the bottom-right corner.
  final bool? isOnline;

  static String initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = String.fromCharCode(words.first.runes.first).toUpperCase();
    if (words.length == 1) return first;
    final second = String.fromCharCode(words.last.runes.first).toUpperCase();
    return '$first$second';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final surface = Theme.of(context).colorScheme.surface;
    final online = isOnline;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ExcludeSemantics(
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.avatarColorFor(peerId),
              ),
              child: Text(
                initialsOf(name),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.avatarForeground,
                  fontSize: size * 0.38,
                ),
              ),
            ),
          ),
          if (online != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surface,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: StatusDot(isOnline: online),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
