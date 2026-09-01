import 'package:flutter/material.dart';

import '../core/skins.dart';

/// Persisted appearance preferences.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.skin = AppSkin.classic,
  });

  final ThemeMode themeMode;
  final AppSkin skin;

  AppSettings copyWith({
    ThemeMode? themeMode,
    AppSkin? skin,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      skin: skin ?? this.skin,
    );
  }
}
