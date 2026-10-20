import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/settings_provider.dart';

/// The selected skin's picture, shown on Home.
class SkinArtworkBanner extends ConsumerWidget {
  const SkinArtworkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(settingsProvider).skin.previewAsset;
    if (asset == null) {
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

/// A faded copy of the skin picture behind a workout.
class SkinArtworkBackdrop extends ConsumerWidget {
  const SkinArtworkBackdrop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(settingsProvider).skin.previewAsset;
    if (asset == null) {
      return const SizedBox.shrink();
    }

    final scrim = Theme.of(context).scaffoldBackgroundColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover),
        ColoredBox(color: scrim.withValues(alpha: 0.78)),
      ],
    );
  }
}
