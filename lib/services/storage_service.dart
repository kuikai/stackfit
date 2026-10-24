import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/skins.dart';
import '../models/models.dart';

/// Local persistence for workouts, history, Pro status, and settings.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _workoutsKey = 'stackfit_workouts';
  static const _sessionsKey = 'stackfit_completed_sessions';
  static const _isProKey = 'stackfit_is_pro';
  static const _themeModeKey = 'stackfit_theme_mode';
  static const _skinKey = 'stackfit_skin';
  static const _customExercisesKey = 'stackfit_custom_exercises';

  // ── Workouts ──────────────────────────────────────────────────────────────

  List<Workout> loadWorkouts() {
    final raw = _prefs.getString(_workoutsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Workout.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveWorkouts(List<Workout> workouts) async {
    final encoded = jsonEncode(
      workouts.map((workout) => workout.toJson()).toList(),
    );
    await _prefs.setString(_workoutsKey, encoded);
  }

  // ── Completed sessions ────────────────────────────────────────────────────

  List<CompletedSession> loadCompletedSessions() {
    final raw = _prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map(
            (item) => CompletedSession.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCompletedSessions(List<CompletedSession> sessions) async {
    final encoded = jsonEncode(
      sessions.map((session) => session.toJson()).toList(),
    );
    await _prefs.setString(_sessionsKey, encoded);
  }

  // ── Pro status ────────────────────────────────────────────────────────────

  bool loadIsPro() => _prefs.getBool(_isProKey) ?? false;

  Future<void> saveIsPro(bool isPro) async {
    await _prefs.setBool(_isProKey, isPro);
  }

  // ── Appearance ────────────────────────────────────────────────────────────

  AppSettings loadSettings() {
    return AppSettings(
      themeMode: loadThemeMode(),
      skin: loadSkin(),
    );
  }

  ThemeMode loadThemeMode() {
    final raw = _prefs.getString(_themeModeKey);
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeModeKey, value);
  }

  AppSkin loadSkin() => AppSkin.fromStorage(_prefs.getString(_skinKey));

  Future<void> saveSkin(AppSkin skin) async {
    await _prefs.setString(_skinKey, skin.name);
  }

  // ── Custom catalog ────────────────────────────────────────────────────────

  List<CatalogExercise> loadCustomExercises() {
    final raw = _prefs.getString(_customExercisesKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => CatalogExercise.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Saved JSON was unreadable. Start from an empty custom catalog.
      return const [];
    }
  }

  Future<void> saveCustomExercises(List<CatalogExercise> exercises) async {
    final encoded = jsonEncode(
      exercises.map((exercise) => exercise.toJson()).toList(),
    );
    await _prefs.setString(_customExercisesKey, encoded);
  }
}
