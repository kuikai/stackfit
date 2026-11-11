import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Home holder that stays solid on everyday skins and turns glass on Cyberpunk.
///
/// Flutter [Card] paints an opaque plate, so glass skins use a [Container]
/// with a pale wash instead.
class SkinPanel extends StatelessWidget {
  const SkinPanel({
    super.key,
    required this.child,
    this.margin,
    this.color,
    this.borderRadius,
    this.overPortrait = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  /// Overrides the skin's usual round corners (folder shells use this).
  final BorderRadius? borderRadius;

  /// Darker frost so names stay readable on the big Home picture.
  final bool overPortrait;

  @override
  Widget build(BuildContext context) {
    final look = context.skinLook;
    final colors = Theme.of(context).colorScheme;
    final radius = borderRadius ?? look.cornerRadius;
    if (look.cardOpacity >= 1) {
      return Card(
        margin: margin,
        color: color,
        shape: RoundedRectangleBorder(borderRadius: radius),
        child: child,
      );
    }
    return Container(
      margin: margin,
      decoration: look.cardDecoration(
        colors,
        color: color,
        overPortrait: overPortrait,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
