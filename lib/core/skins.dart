import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

part 'skin_looks.dart';
part 'skin_palettes.dart';

/// Visual style presets for StackFit.
/// Everyday skins stay free. Fun skins set [pro] and show under Pro skins.
enum AppSkin {
  classic,
  midnight,
  forest,
  sunset,
  minimal,
  synthwave,
  boldSports,
  chibi,
  cyberpunk,
  dumbbell;

  // Anime skins stay free until purchases exist, so nothing passes true yet.
  // ignore: unused_element_parameter
  const AppSkin({this.pro = false});

  /// True for fun themes such as anime. They live in the Pro skins section.
  final bool pro;

  static List<AppSkin> get standardSkins => [
    for (final skin in values)
      if (!skin.pro) skin,
  ];

  static List<AppSkin> get proSkins => [
    for (final skin in values)
      if (skin.pro) skin,
  ];

  String get displayName => switch (this) {
    AppSkin.classic => 'Classic',
    AppSkin.midnight => 'Midnight',
    AppSkin.forest => 'Forest',
    AppSkin.sunset => 'Sunset',
    AppSkin.minimal => 'Minimal',
    AppSkin.synthwave => 'Synthwave',
    AppSkin.boldSports => 'Bold Sports',
    AppSkin.chibi => 'Chibi',
    AppSkin.cyberpunk => 'Cyberpunk',
    AppSkin.dumbbell => 'Dumbbell',
  };

  String get description => switch (this) {
    AppSkin.classic => 'Fresh athletic green',
    AppSkin.midnight => 'Gym-ready cool blue',
    AppSkin.forest => 'Calm earthy focus',
    AppSkin.sunset => 'Warm energetic coral',
    AppSkin.minimal => 'Quiet premium neutrals',
    AppSkin.synthwave => 'Neon pink & cyan fun',
    AppSkin.boldSports => 'High-energy neon pink sports anime',
    AppSkin.chibi => 'Soft pastel cute anime',
    AppSkin.cyberpunk => 'Neon cyan and magenta night city',
    AppSkin.dumbbell => 'Bright warm gym anime style',
  };

  /// Banner shown on the skin card. Everyday skins stay colour-only.
  String? get previewAsset => switch (this) {
    AppSkin.boldSports => 'StackFitWeb/themes/bold-sports/icons/banner.jpg',
    AppSkin.chibi => 'StackFitWeb/themes/chibi/icons/banner.jpg',
    AppSkin.cyberpunk => 'StackFitWeb/themes/cyberpunk/icons/banner.jpg',
    AppSkin.dumbbell => 'StackFitWeb/themes/dumbbell/icons/banner-home.jpg',
    _ => null,
  };

  /// Full-screen plate. When set, Home skips the banner and paints this behind the list.
  String? get backgroundAsset => switch (this) {
    AppSkin.cyberpunk => 'StackFitWeb/themes/cyberpunk/background.jpg',
    _ => null,
  };

  static AppSkin fromStorage(String? value) {
    return AppSkin.values.firstWhere(
      (skin) => skin.name == value,
      orElse: () => AppSkin.classic,
    );
  }
}

/// Typeface used by a skin. Some skins pair a display face with a body face.
enum SkinTypeface {
  plusJakartaSans,
  spaceGrotesk,
  nunito,
  outfit,
  inter,
  rajdhani,
  orbitron,
}

/// Font, corners, and spacing for one skin. Colors stay on [SkinPalette].
class SkinLook extends ThemeExtension<SkinLook> {
  const SkinLook({
    required this.bodyFont,
    required this.displayFont,
    required this.radius,
    required this.radiusSmall,
    required this.pagePadding,
    required this.listGap,
    required this.buttonPaddingHorizontal,
    required this.buttonPaddingVertical,
  });

  final SkinTypeface bodyFont;
  final SkinTypeface displayFont;
  final double radius;
  final double radiusSmall;
  final double pagePadding;
  final double listGap;
  final double buttonPaddingHorizontal;
  final double buttonPaddingVertical;

  EdgeInsets get buttonPadding => EdgeInsets.symmetric(
    horizontal: buttonPaddingHorizontal,
    vertical: buttonPaddingVertical,
  );

  EdgeInsets get outlinedButtonPadding => EdgeInsets.symmetric(
    horizontal: buttonPaddingHorizontal - 6,
    vertical: buttonPaddingVertical - 2,
  );

  double get filledButtonHeight => buttonPaddingVertical * 2 + 24;

  double get outlinedButtonHeight => (buttonPaddingVertical - 2) * 2 + 24;

  BorderRadius get cornerRadius => BorderRadius.circular(radius);

  BorderRadius get cornerRadiusSmall => BorderRadius.circular(radiusSmall);

  @override
  SkinLook copyWith({
    SkinTypeface? bodyFont,
    SkinTypeface? displayFont,
    double? radius,
    double? radiusSmall,
    double? pagePadding,
    double? listGap,
    double? buttonPaddingHorizontal,
    double? buttonPaddingVertical,
  }) {
    return SkinLook(
      bodyFont: bodyFont ?? this.bodyFont,
      displayFont: displayFont ?? this.displayFont,
      radius: radius ?? this.radius,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      pagePadding: pagePadding ?? this.pagePadding,
      listGap: listGap ?? this.listGap,
      buttonPaddingHorizontal:
          buttonPaddingHorizontal ?? this.buttonPaddingHorizontal,
      buttonPaddingVertical:
          buttonPaddingVertical ?? this.buttonPaddingVertical,
    );
  }

  @override
  SkinLook lerp(SkinLook? other, double t) {
    if (other == null) {
      return this;
    }
    final useOther = t >= 0.5;
    return SkinLook(
      bodyFont: useOther ? other.bodyFont : bodyFont,
      displayFont: useOther ? other.displayFont : displayFont,
      radius: lerpDouble(radius, other.radius, t)!,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t)!,
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t)!,
      listGap: lerpDouble(listGap, other.listGap, t)!,
      buttonPaddingHorizontal: lerpDouble(
        buttonPaddingHorizontal,
        other.buttonPaddingHorizontal,
        t,
      )!,
      buttonPaddingVertical: lerpDouble(
        buttonPaddingVertical,
        other.buttonPaddingVertical,
        t,
      )!,
    );
  }
}

/// Color tokens for one skin at one brightness.
/// One strong [primary] accent drives the athletic feel.
class SkinPalette {
  const SkinPalette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
  });

  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;

  ColorScheme toColorScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );

    return base.copyWith(
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      tertiary: secondary,
      onTertiary: onSecondary,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerLowest: background,
      surfaceContainerLow: surface,
      surfaceContainer: Color.lerp(surface, primary, 0.04)!,
      surfaceContainerHigh: Color.lerp(surface, primary, 0.07)!,
      surfaceContainerHighest: Color.lerp(surface, primary, 0.1)!,
      primaryContainer: Color.lerp(primary, surface, 0.78)!,
      onPrimaryContainer: Color.lerp(primary, onSurface, 0.35)!,
    );
  }
}

/// Resolves Clean Athletic palettes for each [AppSkin].
class AppSkins {
  AppSkins._();

  static SkinPalette palette(AppSkin skin, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (skin) {
      AppSkin.classic => isDark ? _classicDark : _classicLight,
      AppSkin.midnight => isDark ? _midnightDark : _midnightLight,
      AppSkin.forest => isDark ? _forestDark : _forestLight,
      AppSkin.sunset => isDark ? _sunsetDark : _sunsetLight,
      AppSkin.minimal => isDark ? _minimalDark : _minimalLight,
      AppSkin.synthwave => isDark ? _synthwaveDark : _synthwaveLight,
      AppSkin.boldSports => isDark ? _boldSportsDark : _boldSportsLight,
      AppSkin.chibi => isDark ? _chibiDark : _chibiLight,
      AppSkin.cyberpunk => isDark ? _cyberpunkDark : _cyberpunkLight,
      AppSkin.dumbbell => isDark ? _dumbbellDark : _dumbbellLight,
    };
  }

  static SkinLook look(AppSkin skin) {
    return switch (skin) {
      AppSkin.classic => _classicLook,
      AppSkin.midnight => _midnightLook,
      AppSkin.forest => _forestLook,
      AppSkin.sunset => _sunsetLook,
      AppSkin.minimal => _minimalLook,
      AppSkin.synthwave => _synthwaveLook,
      AppSkin.boldSports => _boldSportsLook,
      AppSkin.chibi => _chibiLook,
      AppSkin.cyberpunk => _cyberpunkLook,
      AppSkin.dumbbell => _dumbbellLook,
    };
  }
}
