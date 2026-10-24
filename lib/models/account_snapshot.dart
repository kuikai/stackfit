import 'dart:convert';

import 'catalog_exercise.dart';
import 'completed_session.dart';
import 'workout.dart';

/// A workout removed on one device. The newer timestamp wins against edits.
class WorkoutDeletion {
  const WorkoutDeletion({required this.id, required this.deletedAt});

  final String id;
  final DateTime deletedAt;

  Map<String, dynamic> toJson() {
    return {'id': id, 'deletedAt': deletedAt.toIso8601String()};
  }

  factory WorkoutDeletion.fromJson(Map<String, dynamic> json) {
    return WorkoutDeletion(
      id: json['id'] as String,
      deletedAt: DateTime.parse(json['deletedAt'] as String),
    );
  }
}

/// Workouts, history, custom exercises, and appearance saved for one account.
///
/// Pro is intentionally absent. It stays a store purchase on the device.
class AccountSnapshot {
  const AccountSnapshot({
    required this.workouts,
    required this.deletedWorkouts,
    required this.sessions,
    required this.themeMode,
    required this.skin,
    required this.appearanceUpdatedAt,
    this.customExercises = const [],
  });

  factory AccountSnapshot.empty() {
    return AccountSnapshot(
      workouts: const [],
      deletedWorkouts: const [],
      sessions: const [],
      customExercises: const [],
      themeMode: 'system',
      skin: 'classic',
      appearanceUpdatedAt: DateTime.utc(1970),
    );
  }

  final List<Workout> workouts;
  final List<WorkoutDeletion> deletedWorkouts;
  final List<CompletedSession> sessions;

  /// Exercises the user added. Shown in the catalog under Custom.
  final List<CatalogExercise> customExercises;

  /// `system`, `light`, or `dark`.
  final String themeMode;
  final String skin;
  final DateTime appearanceUpdatedAt;

  AccountSnapshot copyWith({
    List<Workout>? workouts,
    List<WorkoutDeletion>? deletedWorkouts,
    List<CompletedSession>? sessions,
    List<CatalogExercise>? customExercises,
    String? themeMode,
    String? skin,
    DateTime? appearanceUpdatedAt,
  }) {
    return AccountSnapshot(
      workouts: workouts ?? this.workouts,
      deletedWorkouts: deletedWorkouts ?? this.deletedWorkouts,
      sessions: sessions ?? this.sessions,
      customExercises: customExercises ?? this.customExercises,
      themeMode: themeMode ?? this.themeMode,
      skin: skin ?? this.skin,
      appearanceUpdatedAt: appearanceUpdatedAt ?? this.appearanceUpdatedAt,
    );
  }

  bool get hasProgress =>
      workouts.isNotEmpty || sessions.isNotEmpty || customExercises.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'workouts': workouts.map((workout) => workout.toJson()).toList(),
      'deletedWorkouts': deletedWorkouts
          .map((deletion) => deletion.toJson())
          .toList(),
      'sessions': sessions.map((session) => session.toJson()).toList(),
      'customExercises': customExercises
          .map((exercise) => exercise.toJson())
          .toList(),
      'themeMode': themeMode,
      'skin': skin,
      'appearanceUpdatedAt': appearanceUpdatedAt.toIso8601String(),
    };
  }

  /// Stable encoding so two equal snapshots compare the same.
  String get canonicalJson {
    final json = toJson();
    _sortById(json['workouts'] as List<dynamic>);
    _sortById(json['deletedWorkouts'] as List<dynamic>);
    _sortById(json['sessions'] as List<dynamic>);
    _sortById(json['customExercises'] as List<dynamic>);
    return jsonEncode(json);
  }

  factory AccountSnapshot.fromJson(Map<String, dynamic> json) {
    return AccountSnapshot(
      workouts: _mapList(json['workouts'], Workout.fromJson),
      deletedWorkouts: _mapList(
        json['deletedWorkouts'],
        WorkoutDeletion.fromJson,
      ),
      sessions: _mapList(json['sessions'], CompletedSession.fromJson),
      customExercises: _mapList(
        json['customExercises'],
        CatalogExercise.fromJson,
      ),
      themeMode: json['themeMode'] as String? ?? 'system',
      skin: json['skin'] as String? ?? 'classic',
      appearanceUpdatedAt:
          DateTime.tryParse(json['appearanceUpdatedAt'] as String? ?? '') ??
          DateTime.utc(1970),
    );
  }
}

List<T> _mapList<T>(Object? raw, T Function(Map<String, dynamic> json) decode) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .whereType<Map<dynamic, dynamic>>()
      .map((item) => decode(Map<String, dynamic>.from(item)))
      .toList();
}

void _sortById(List<dynamic> items) {
  items.sort((a, b) {
    final aId = (a as Map)['id'] as String? ?? '';
    final bId = (b as Map)['id'] as String? ?? '';
    return aId.compareTo(bId);
  });
}
