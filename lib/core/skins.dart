import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

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

  const AppSkin({this.pro = false});

  /// True for fun themes such as anime. They live in the Pro skins section.
  final bool pro;

  static List<AppSkin> get standardSkins =>
      [for (final skin in values) if (!skin.pro) skin];

  static List<AppSkin> get proSkins =>
      [for (final skin in values) if (skin.pro) skin];

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

  /// Banner shown on the Pro skin card. Everyday skins stay colour-only.
  String? get previewAsset => switch (this) {
    AppSkin.boldSports => 'StackFitWeb/themes/bold-sports/icons/banner.jpg',
    AppSkin.chibi => 'StackFitWeb/themes/chibi/icons/banner.jpg',
    AppSkin.cyberpunk => 'StackFitWeb/themes/cyberpunk/icons/banner.jpg',
    AppSkin.dumbbell => 'StackFitWeb/themes/dumbbell/icons/banner-home.jpg',
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

  static const _classicLook = SkinLook(
    bodyFont: SkinTypeface.plusJakartaSans,
    displayFont: SkinTypeface.plusJakartaSans,
    radius: 18,
    radiusSmall: 14,
    pagePadding: 16,
    listGap: 12,
    buttonPaddingHorizontal: 24,
    buttonPaddingVertical: 14,
  );

  static const _midnightLook = SkinLook(
    bodyFont: SkinTypeface.spaceGrotesk,
    displayFont: SkinTypeface.spaceGrotesk,
    radius: 10,
    radiusSmall: 8,
    pagePadding: 12,
    listGap: 8,
    buttonPaddingHorizontal: 18,
    buttonPaddingVertical: 10,
  );

  static const _forestLook = SkinLook(
    bodyFont: SkinTypeface.nunito,
    displayFont: SkinTypeface.nunito,
    radius: 28,
    radiusSmall: 20,
    pagePadding: 22,
    listGap: 16,
    buttonPaddingHorizontal: 28,
    buttonPaddingVertical: 16,
  );

  static const _sunsetLook = SkinLook(
    bodyFont: SkinTypeface.outfit,
    displayFont: SkinTypeface.outfit,
    radius: 20,
    radiusSmall: 16,
    pagePadding: 16,
    listGap: 12,
    buttonPaddingHorizontal: 24,
    buttonPaddingVertical: 14,
  );

  static const _minimalLook = SkinLook(
    bodyFont: SkinTypeface.inter,
    displayFont: SkinTypeface.inter,
    radius: 4,
    radiusSmall: 4,
    pagePadding: 12,
    listGap: 8,
    buttonPaddingHorizontal: 18,
    buttonPaddingVertical: 10,
  );

  static const _synthwaveLook = SkinLook(
    bodyFont: SkinTypeface.rajdhani,
    displayFont: SkinTypeface.orbitron,
    radius: 6,
    radiusSmall: 4,
    pagePadding: 12,
    listGap: 8,
    buttonPaddingHorizontal: 18,
    buttonPaddingVertical: 10,
  );

  static const _boldSportsLook = SkinLook(
    bodyFont: SkinTypeface.rajdhani,
    displayFont: SkinTypeface.orbitron,
    radius: 8,
    radiusSmall: 6,
    pagePadding: 12,
    listGap: 8,
    buttonPaddingHorizontal: 18,
    buttonPaddingVertical: 10,
  );

  static const _chibiLook = SkinLook(
    bodyFont: SkinTypeface.nunito,
    displayFont: SkinTypeface.nunito,
    radius: 28,
    radiusSmall: 22,
    pagePadding: 22,
    listGap: 16,
    buttonPaddingHorizontal: 28,
    buttonPaddingVertical: 16,
  );

  static const _cyberpunkLook = SkinLook(
    bodyFont: SkinTypeface.spaceGrotesk,
    displayFont: SkinTypeface.orbitron,
    radius: 4,
    radiusSmall: 4,
    pagePadding: 12,
    listGap: 8,
    buttonPaddingHorizontal: 18,
    buttonPaddingVertical: 10,
  );

  static const _dumbbellLook = SkinLook(
    bodyFont: SkinTypeface.outfit,
    displayFont: SkinTypeface.outfit,
    radius: 20,
    radiusSmall: 16,
    pagePadding: 16,
    listGap: 12,
    buttonPaddingHorizontal: 24,
    buttonPaddingVertical: 14,
  );

  static const _classicLight = SkinPalette(
    primary: Color(0xFF0F9F6E),
    secondary: Color(0xFF5B8A78),
    background: Color(0xFFF3F6F4),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF122018),
    onSurface: Color(0xFF122018),
  );

  static const _classicDark = SkinPalette(
    primary: Color(0xFF3DDB9A),
    secondary: Color(0xFF7AA894),
    background: Color(0xFF0B1210),
    surface: Color(0xFF141C19),
    onPrimary: Color(0xFF003822),
    onSecondary: Color(0xFF0B1210),
    onBackground: Color(0xFFE7F2EC),
    onSurface: Color(0xFFE7F2EC),
  );

  static const _midnightLight = SkinPalette(
    primary: Color(0xFF3B6BF5),
    secondary: Color(0xFF6B7C9C),
    background: Color(0xFFF2F4F9),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF121722),
    onSurface: Color(0xFF121722),
  );

  static const _midnightDark = SkinPalette(
    primary: Color(0xFF6B8CFF),
    secondary: Color(0xFF8FA0C0),
    background: Color(0xFF0A0E18),
    surface: Color(0xFF131925),
    onPrimary: Color(0xFF0A1024),
    onSecondary: Color(0xFF0A0E18),
    onBackground: Color(0xFFE8EDF8),
    onSurface: Color(0xFFE8EDF8),
  );

  static const _forestLight = SkinPalette(
    primary: Color(0xFF2E7D4F),
    secondary: Color(0xFF8A7355),
    background: Color(0xFFF4F2EC),
    surface: Color(0xFFFFFCF7),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF172016),
    onSurface: Color(0xFF172016),
  );

  static const _forestDark = SkinPalette(
    primary: Color(0xFF5FCF84),
    secondary: Color(0xFFB89A72),
    background: Color(0xFF0D130E),
    surface: Color(0xFF161E16),
    onPrimary: Color(0xFF003918),
    onSecondary: Color(0xFF1A140C),
    onBackground: Color(0xFFE8F0E7),
    onSurface: Color(0xFFE8F0E7),
  );

  static const _sunsetLight = SkinPalette(
    primary: Color(0xFFE85A3C),
    secondary: Color(0xFFC48A5A),
    background: Color(0xFFFFF5F1),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF271612),
    onSurface: Color(0xFF271612),
  );

  static const _sunsetDark = SkinPalette(
    primary: Color(0xFFFF7A5C),
    secondary: Color(0xFFE0A878),
    background: Color(0xFF140E0D),
    surface: Color(0xFF1E1513),
    onPrimary: Color(0xFF3A1008),
    onSecondary: Color(0xFF241408),
    onBackground: Color(0xFFFFEBE5),
    onSurface: Color(0xFFFFEBE5),
  );

  static const _minimalLight = SkinPalette(
    primary: Color(0xFF222222),
    secondary: Color(0xFF6E6E6E),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF171717),
    onSurface: Color(0xFF171717),
  );

  static const _minimalDark = SkinPalette(
    primary: Color(0xFFF2F2F2),
    secondary: Color(0xFF9A9A9A),
    background: Color(0xFF0C0C0C),
    surface: Color(0xFF171717),
    onPrimary: Color(0xFF111111),
    onSecondary: Color(0xFF111111),
    onBackground: Color(0xFFF2F2F2),
    onSurface: Color(0xFFF2F2F2),
  );

  static const _synthwaveLight = SkinPalette(
    primary: Color(0xFFE0187A),
    secondary: Color(0xFF00B8D4),
    background: Color(0xFFF7F0FB),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF002028),
    onBackground: Color(0xFF241033),
    onSurface: Color(0xFF241033),
  );

  static const _synthwaveDark = SkinPalette(
    primary: Color(0xFFFF2D95),
    secondary: Color(0xFF00E5FF),
    background: Color(0xFF0B0218),
    surface: Color(0xFF160B28),
    onPrimary: Color(0xFF1A0012),
    onSecondary: Color(0xFF001820),
    onBackground: Color(0xFFFFEAF5),
    onSurface: Color(0xFFFFEAF5),
  );

  static const _boldSportsLight = SkinPalette(
    primary: Color(0xFFE0187A),
    secondary: Color(0xFFFFB703),
    background: Color(0xFFFFF1F7),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF3A2200),
    onBackground: Color(0xFF2A1020),
    onSurface: Color(0xFF2A1020),
  );

  static const _boldSportsDark = SkinPalette(
    primary: Color(0xFFFF2D95),
    secondary: Color(0xFFFFD60A),
    background: Color(0xFF12040C),
    surface: Color(0xFF1E0A16),
    onPrimary: Color(0xFF1A0012),
    onSecondary: Color(0xFF2A1A00),
    onBackground: Color(0xFFFFE6F2),
    onSurface: Color(0xFFFFE6F2),
  );

  static const _chibiLight = SkinPalette(
    primary: Color(0xFFFF8FB8),
    secondary: Color(0xFFC4B5FD),
    background: Color(0xFFFFF6FB),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF3D2030),
    onSecondary: Color(0xFF2A2040),
    onBackground: Color(0xFF3A2A38),
    onSurface: Color(0xFF3A2A38),
  );

  static const _chibiDark = SkinPalette(
    primary: Color(0xFFFFB7D5),
    secondary: Color(0xFFD4C4FF),
    background: Color(0xFF1A121C),
    surface: Color(0xFF261A28),
    onPrimary: Color(0xFF3A1830),
    onSecondary: Color(0xFF241838),
    onBackground: Color(0xFFFFF0F8),
    onSurface: Color(0xFFFFF0F8),
  );

  static const _cyberpunkLight = SkinPalette(
    primary: Color(0xFF00C2E0),
    secondary: Color(0xFFFF2D95),
    background: Color(0xFFF2FBFD),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFF002028),
    onSecondary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF0B1A22),
    onSurface: Color(0xFF0B1A22),
  );

  static const _cyberpunkDark = SkinPalette(
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFFFF2D95),
    background: Color(0xFF05060F),
    surface: Color(0xFF10141F),
    onPrimary: Color(0xFF001418),
    onSecondary: Color(0xFF1A0012),
    onBackground: Color(0xFFE8FBFF),
    onSurface: Color(0xFFE8FBFF),
  );

  static const _dumbbellLight = SkinPalette(
    primary: Color(0xFFFF6B4A),
    secondary: Color(0xFFFFC43D),
    background: Color(0xFFFFF8F0),
    surface: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFF3A2200),
    onBackground: Color(0xFF2A160C),
    onSurface: Color(0xFF2A160C),
  );

  static const _dumbbellDark = SkinPalette(
    primary: Color(0xFFFF8A5B),
    secondary: Color(0xFFFFD166),
    background: Color(0xFF1A100C),
    surface: Color(0xFF261812),
    onPrimary: Color(0xFF3A1408),
    onSecondary: Color(0xFF2A1A00),
    onBackground: Color(0xFFFFF3E8),
    onSurface: Color(0xFFFFF3E8),
  );
}
