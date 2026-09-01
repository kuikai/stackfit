import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/skins.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(storageServiceProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._storage) : super(_storage.loadSettings());

  final StorageService _storage;

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _storage.saveThemeMode(mode);
  }

  Future<void> setSkin(AppSkin skin) async {
    state = state.copyWith(skin: skin);
    await _storage.saveSkin(skin);
  }
}
