import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/account_snapshot.dart';
import 'package:stackfit/models/completed_session.dart';
import 'package:stackfit/models/exercise.dart';
import 'package:stackfit/models/workout.dart';
import 'package:stackfit/services/account/snapshot_merge.dart';

void main() {
  test('newer workout updatedAt wins', () {
    final older = _workout('same', DateTime.utc(2026, 1, 1), 'Old');
    final newer = _workout('same', DateTime.utc(2026, 2, 1), 'New');

    final merged = mergeSnapshots(
      _snapshot(workouts: [older]),
      _snapshot(workouts: [newer]),
    );

    expect(merged.workouts, hasLength(1));
    expect(merged.workouts.single.name, 'New');
  });

  test('a newer deletion removes the workout', () {
    final workout = _workout('lift', DateTime.utc(2026, 1, 1), 'Lift');
    final deletion = SnapshotDeletion(
      id: 'lift',
      deletedAt: DateTime.utc(2026, 3, 1),
    );

    final merged = mergeSnapshots(
      _snapshot(workouts: [workout]),
      _snapshot(deletedWorkouts: [deletion]),
    );

    expect(merged.workouts, isEmpty);
    expect(merged.deletedWorkouts.single.id, 'lift');
  });

  test('an edit newer than a deletion keeps the workout', () {
    final workout = _workout('lift', DateTime.utc(2026, 4, 1), 'Lift');
    final deletion = SnapshotDeletion(
      id: 'lift',
      deletedAt: DateTime.utc(2026, 3, 1),
    );

    final merged = mergeSnapshots(
      _snapshot(deletedWorkouts: [deletion]),
      _snapshot(workouts: [workout]),
    );

    expect(merged.workouts.single.name, 'Lift');
    expect(merged.deletedWorkouts, isEmpty);
  });

  test('the same session id is stored once', () {
    final first = _session('session-1');
    final again = _session('session-1');
    final other = _session('session-2');

    final merged = mergeSnapshots(
      _snapshot(sessions: [first, other]),
      _snapshot(sessions: [again]),
    );

    expect(merged.sessions.map((session) => session.id), [
      'session-2',
      'session-1',
    ]);
  });

  test('a session deletion drops the session', () {
    final session = _session('session-1');
    final deletion = SnapshotDeletion(
      id: 'session-1',
      deletedAt: DateTime.utc(2026, 3, 1),
    );

    final merged = mergeSnapshots(
      _snapshot(sessions: [session]),
      _snapshot(deletedSessions: [deletion]),
    );

    expect(merged.sessions, isEmpty);
    expect(merged.deletedSessions.single.id, 'session-1');
  });

  test('a trimmed local session does not beat a deletion', () {
    final trimmed = CompletedSession(
      id: 'session-1',
      workoutId: 'workout',
      workoutName: 'Push',
      completedAt: DateTime.utc(2026, 4, 1),
      durationSeconds: 60,
      totalExercises: 1,
    );
    final deletion = SnapshotDeletion(
      id: 'session-1',
      deletedAt: DateTime.utc(2026, 3, 1),
    );

    final merged = mergeSnapshots(
      _snapshot(sessions: [trimmed]),
      _snapshot(deletedSessions: [deletion]),
    );

    expect(merged.sessions, isEmpty);
    expect(merged.deletedSessions.single.id, 'session-1');
  });

  test('newer appearance wins', () {
    final merged = mergeSnapshots(
      _snapshot(skin: 'forest', appearanceUpdatedAt: DateTime.utc(2026, 5, 1)),
      _snapshot(skin: 'sunset', appearanceUpdatedAt: DateTime.utc(2026, 1, 1)),
    );

    expect(merged.skin, 'forest');
    expect(merged.themeMode, 'dark');
  });
}

AccountSnapshot _snapshot({
  List<Workout> workouts = const [],
  List<SnapshotDeletion> deletedWorkouts = const [],
  List<CompletedSession> sessions = const [],
  List<SnapshotDeletion> deletedSessions = const [],
  String skin = 'classic',
  DateTime? appearanceUpdatedAt,
}) {
  return AccountSnapshot(
    workouts: workouts,
    deletedWorkouts: deletedWorkouts,
    sessions: sessions,
    deletedSessions: deletedSessions,
    themeMode: 'dark',
    skin: skin,
    appearanceUpdatedAt: appearanceUpdatedAt ?? DateTime.utc(1970),
  );
}

Workout _workout(String id, DateTime updatedAt, String name) {
  return Workout(
    id: id,
    name: name,
    exercises: [
      Exercise.timer(
        id: '$id-exercise',
        name: 'Plank',
        workSeconds: 30,
        restSeconds: 10,
      ),
    ],
    createdAt: updatedAt,
    updatedAt: updatedAt,
  );
}

CompletedSession _session(String id) {
  return CompletedSession(
    id: id,
    workoutId: 'workout',
    workoutName: 'Push',
    completedAt: id == 'session-2'
        ? DateTime.utc(2026, 2, 2)
        : DateTime.utc(2026, 1, 1),
    durationSeconds: 60,
    totalExercises: 1,
  );
}
