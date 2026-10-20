import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/skins.dart';
import '../models/app_settings.dart';
import '../services/account/account_storage.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(accountStorageProvider),
  );
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._storage, this._accountStorage)
      : super(_storage.loadSettings());

  final StorageService _storage;
  final AccountStorage _accountStorage;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _touchAppearance();
    state = state.copyWith(themeMode: mode);
    await _storage.saveThemeMode(mode);
  }

  Future<void> setSkin(AppSkin skin) async {
    await _touchAppearance();
    state = state.copyWith(skin: skin);
    await _storage.saveSkin(skin);
  }

  /// Applies appearance downloaded for the signed-in account.
  Future<void> applyFromAccount({
    required ThemeMode themeMode,
    required AppSkin skin,
  }) async {
    state = AppSettings(themeMode: themeMode, skin: skin);
    await _storage.saveThemeMode(themeMode);
    await _storage.saveSkin(skin);
  }

  Future<void> _touchAppearance() {
    return _accountStorage.setAppearanceUpdatedAt(DateTime.now().toUtc());
  }
}
