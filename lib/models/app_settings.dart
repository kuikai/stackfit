import 'package:flutter/material.dart';

import '../core/skins.dart';

/// Theme, skin, and sound saved on this phone.
/// Sound is not part of the account snapshot.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.skin = AppSkin.classic,
    this.soundEnabled = true,
    this.soundVolume = 0.8,
  });

  final ThemeMode themeMode;
  final AppSkin skin;

  /// When false, phase beeps stay silent. The phone can still vibrate.
  final bool soundEnabled;

  /// Playback level from 0 to 1. Zero is silent even when [soundEnabled] is on.
  final double soundVolume;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppSkin? skin,
    bool? soundEnabled,
    double? soundVolume,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      skin: skin ?? this.skin,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      soundVolume: soundVolume ?? this.soundVolume,
    );
  }
}
