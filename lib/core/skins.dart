import 'package:flutter/material.dart';

/// Visual style presets for StackFit (Clean Athletic).
enum AppSkin {
  classic,
  midnight,
  forest,
  sunset,
  minimal,
  synthwave;

  String get displayName => switch (this) {
        AppSkin.classic => 'Classic',
        AppSkin.midnight => 'Midnight',
        AppSkin.forest => 'Forest',
        AppSkin.sunset => 'Sunset',
        AppSkin.minimal => 'Minimal',
        AppSkin.synthwave => 'Synthwave',
      };

  String get description => switch (this) {
        AppSkin.classic => 'Fresh athletic green',
        AppSkin.midnight => 'Gym-ready cool blue',
        AppSkin.forest => 'Calm earthy focus',
        AppSkin.sunset => 'Warm energetic coral',
        AppSkin.minimal => 'Quiet premium neutrals',
        AppSkin.synthwave => 'Neon pink & cyan fun',
      };

  static AppSkin fromStorage(String? value) {
    return AppSkin.values.firstWhere(
      (skin) => skin.name == value,
      orElse: () => AppSkin.classic,
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
    };
  }

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
}
