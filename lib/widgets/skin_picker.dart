import 'package:flutter/material.dart';

import '../core/skins.dart';
import '../core/theme.dart';

/// Selectable grid of skins. [skins] is either the everyday set or Pro skins.
class SkinPicker extends StatelessWidget {
  const SkinPicker({
    super.key,
    required this.skins,
    required this.selected,
    required this.onSelected,
    this.emptyMessage,
  });

  final List<AppSkin> skins;
  final AppSkin selected;
  final ValueChanged<AppSkin> onSelected;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (skins.isEmpty) {
      return Text(
        emptyMessage ?? 'Nothing here yet.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(
            alpha: 0.62,
          ),
          height: 1.4,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: skins.length,
      itemBuilder: (context, index) {
        final skin = skins[index];
        return _SkinCard(
          skin: skin,
          selected: skin == selected,
          onTap: () => onSelected(skin),
        );
      },
    );
  }
}

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final AppSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final palette = AppSkins.palette(skin, brightness);
    final look = AppSkins.look(skin);
    final radius = look.cornerRadius;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? palette.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.14 : 0.06),
                blurRadius: selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _SkinPreview(
                  skin: skin,
                  look: look,
                  palette: palette,
                  selected: selected,
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Swatch(color: palette.primary),
                          const SizedBox(width: 6),
                          _Swatch(color: palette.secondary),
                          const SizedBox(width: 6),
                          _Swatch(color: palette.background),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        skin.displayName,
                        style: look.bodyFont.style(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: palette.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        skin.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: look.bodyFont.style(
                          color: palette.onSurface.withValues(alpha: 0.58),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
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

class _SkinPreview extends StatelessWidget {
  const _SkinPreview({
    required this.skin,
    required this.look,
    required this.palette,
    required this.selected,
  });

  final AppSkin skin;
  final SkinLook look;
  final SkinPalette palette;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final asset = skin.previewAsset;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(look.radius - 1),
        topRight: Radius.circular(look.radius - 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (asset != null)
            Image.asset(asset, fit: BoxFit.cover)
          else
            _ColourSample(look: look, palette: palette),
          if (selected)
            Positioned(
              right: 8,
              top: 8,
              child: _SelectedMark(color: palette.primary),
            ),
        ],
      ),
    );
  }
}

class _ColourSample extends StatelessWidget {
  const _ColourSample({required this.look, required this.palette});

  final SkinLook look;
  final SkinPalette palette;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.background,
            Color.lerp(palette.background, palette.primary, 0.18)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 12,
            child: _SampleChip(look: look, palette: palette),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Text(
              '12:45',
              style: look.displayFont.style(
                color: palette.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  const _SampleChip({required this.look, required this.palette});

  final SkinLook look;
  final SkinPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: look.cornerRadiusSmall,
      ),
      child: Text(
        'Aa',
        style: look.bodyFont.style(
          color: palette.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SelectedMark extends StatelessWidget {
  const _SelectedMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_circle_rounded, color: color, size: 22),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
    );
  }
}
