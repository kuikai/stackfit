import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/skins.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';

/// Night gym behind every dark screen that has one. Home paints the girl on top.
class SkinAppBackground extends ConsumerWidget {
  const SkinAppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(settingsProvider).skin.backgroundAsset;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (asset == null || !dark) {
      return child;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover, alignment: Alignment.topCenter),
        const ColoredBox(color: Color(0x6605060F)),
        child,
      ],
    );
  }
}

/// The selected skin's picture, shown on Home.
class SkinArtworkBanner extends ConsumerWidget {
  const SkinArtworkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(settingsProvider).skin;
    final asset = skin.previewAsset;
    if (asset == null || skin.homePlateAsset != null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: context.pageGutter(top: 4, bottom: 8),
      child: ClipRRect(
        borderRadius: context.skinLook.cornerRadius,
        child: SizedBox(
          height: 168,
          width: double.infinity,
          child: Image.asset(asset, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Home corner. One mascot, or the companion standing next to her trainer.
class SkinHomeMascots extends ConsumerWidget {
  const SkinHomeMascots({super.key});

  static const _pairSize = 96.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(settingsProvider).skin.mascotPartnerAsset;
    if (partner == null) {
      return const SkinMascot(size: 112, alignment: Alignment.bottomLeft);
    }

    return const Align(
      alignment: Alignment.bottomLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SkinMascot(size: _pairSize, pinned: false),
          SizedBox(width: 2),
          SkinMascot(size: _pairSize, pinned: false, partner: true),
        ],
      ),
    );
  }
}

/// Little character. Does not take taps.
class SkinMascot extends ConsumerWidget {
  const SkinMascot({
    super.key,
    this.size = 128,
    this.width,
    this.height,
    this.alignment = Alignment.bottomRight,
    this.seated = false,
    this.resting = false,
    this.pinned = true,
    this.partner = false,
  });

  final double size;

  /// Width for a wide pose. Height follows the picture unless [height] is set.
  final double? width;

  /// Height for a wide pose. Keeps the layout stable before the picture loads.
  final double? height;
  final Alignment alignment;

  /// Sitting pose, used on the Done button.
  final bool seated;

  /// Lying pose, used on the Skip rest bar.
  final bool resting;

  /// False when a parent already places her, such as on a button.
  final bool pinned;

  /// The trainer beside the companion. On Done he uses the seat picture.
  final bool partner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(settingsProvider).skin;
    final asset = _asset(skin);
    if (asset == null) {
      return const SizedBox.shrink();
    }

    final picture = IgnorePointer(child: _image(asset));
    if (!pinned) {
      return picture;
    }
    return Align(alignment: alignment, child: picture);
  }

  String? _asset(AppSkin skin) {
    if (seated && partner) {
      return skin.mascotSeatPartnerAsset;
    }
    if (resting && partner) {
      return skin.mascotRestPartnerAsset;
    }
    if (partner) {
      return skin.mascotPartnerAsset;
    }
    if (resting) {
      return skin.mascotRestAsset;
    }
    if (seated) {
      return skin.mascotSeatAsset;
    }
    return skin.mascotAsset;
  }

  Widget _image(String asset) {
    return Image.asset(
      asset,
      width: width ?? size,
      height: height ?? (width == null ? size : null),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
