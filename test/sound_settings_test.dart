import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/core/skins.dart';
import 'package:stackfit/models/app_settings.dart';
import 'package:stackfit/providers/settings_provider.dart';
import 'package:stackfit/services/account/account_storage.dart';
import 'package:stackfit/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sound defaults to on at 80 percent', () {
    const settings = AppSettings();

    expect(settings.soundEnabled, isTrue);
    expect(settings.soundVolume, 0.8);
    expect(settings.copyWith(themeMode: ThemeMode.dark).soundEnabled, isTrue);
    expect(settings.copyWith(soundEnabled: false).soundVolume, 0.8);
  });

  test('sound settings round-trip and stay in range', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    await storage.saveSoundEnabled(false);
    await storage.saveSoundVolume(1.4);

    final saved = storage.loadSettings();
    expect(saved.soundEnabled, isFalse);
    expect(saved.soundVolume, 1);

    await prefs.setDouble('stackfit_sound_volume', -0.2);
    expect(storage.loadSoundVolume(), 0);
  });

  test('account appearance leaves sound on this phone', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final accounts = AccountStorage(prefs);
    final settings = SettingsNotifier(storage, accounts);
    addTearDown(settings.dispose);

    await settings.setSoundEnabled(false);
    await settings.setSoundVolume(0.25);
    final before = accounts.loadAppearanceUpdatedAt();

    await settings.applyFromAccount(
      themeMode: ThemeMode.dark,
      skin: AppSkin.forest,
    );

    expect(settings.state.themeMode, ThemeMode.dark);
    expect(settings.state.skin, AppSkin.forest);
    expect(settings.state.soundEnabled, isFalse);
    expect(settings.state.soundVolume, 0.25);
    expect(accounts.loadAppearanceUpdatedAt(), before);

    final loaded = storage.loadSettings();
    expect(loaded.themeMode, ThemeMode.dark);
    expect(loaded.skin, AppSkin.forest);
    expect(loaded.soundEnabled, isFalse);
    expect(loaded.soundVolume, 0.25);
  });
}
