import 'package:flutter/material.dart';

import '../core/skins.dart';
import '../core/theme.dart';

/// Premium selectable grid of Clean Athletic skins.
class SkinPicker extends StatelessWidget {
  const SkinPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final AppSkin selected;
  final ValueChanged<AppSkin> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.92,
      children: [
        for (final skin in AppSkin.values)
          _SkinCard(
            skin: skin,
            selected: skin == selected,
            onTap: () => onSelected(skin),
          ),
      ],
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
    final radius = BorderRadius.circular(AppTheme.radius);

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
                color: Colors.black.withValues(
                  alpha: selected ? 0.14 : 0.06,
                ),
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radius - 1),
                      topRight: Radius.circular(AppTheme.radius - 1),
                    ),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Aa',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: palette.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Text(
                          '12:45',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: palette.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: palette.primary,
                            size: 22,
                          ),
                        ),
                    ],
                  ),
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: palette.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        skin.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.onSurface.withValues(alpha: 0.58),
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
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}
