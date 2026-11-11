import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Which slice of an open Home folder this piece is.
enum FolderShellRole {
  /// Closed folder — one rounded card.
  alone,

  /// Open folder title row — rounded on top only.
  header,

  /// A day in the middle — square, shared fill.
  middle,

  /// Last day — rounded on the bottom only.
  footer,
}

/// One continuous Home folder plate, split into reorderable slices.
///
/// Separate [SkinPanel] cards leave seams (borders + elevation). This paints
/// one shared fill and only draws the outer border, so open days read as
/// inside the folder.
class FolderShell extends StatelessWidget {
  const FolderShell({
    super.key,
    required this.role,
    required this.child,
    this.margin,
  });

  final FolderShellRole role;
  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final look = context.skinLook;
    final colors = Theme.of(context).colorScheme;
    final radius = look.radius;
    final borderColor = colors.primary.withValues(alpha: 0.32);
    final glass = look.cardOpacity < 1;

    final BorderRadius borderRadius = switch (role) {
      FolderShellRole.alone => BorderRadius.circular(radius),
      FolderShellRole.header => BorderRadius.vertical(
        top: Radius.circular(radius),
      ),
      FolderShellRole.middle => BorderRadius.zero,
      FolderShellRole.footer => BorderRadius.vertical(
        bottom: Radius.circular(radius),
      ),
    };

    final Border? border = !glass
        ? null
        : switch (role) {
            FolderShellRole.alone => Border.all(color: borderColor),
            FolderShellRole.header => Border(
              top: BorderSide(color: borderColor),
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
            ),
            FolderShellRole.middle => Border(
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
            ),
            FolderShellRole.footer => Border(
              left: BorderSide(color: borderColor),
              right: BorderSide(color: borderColor),
              bottom: BorderSide(color: borderColor),
            ),
          };

    // Same heavy frost as loose Home tiles over the wallpaper.
    final fill = look.cardFill(colors, overPortrait: glass);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: borderRadius,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
