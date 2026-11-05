import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/account_snapshot.dart';
import 'package:stackfit/models/completed_session.dart';
import 'package:stackfit/models/exercise.dart';
import 'package:stackfit/models/set_log.dart';
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
    final deletion = WorkoutDeletion(
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
    final deletion = WorkoutDeletion(
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

  test('a session deletion removes that history row', () {
    final deletion = WorkoutDeletion(
      id: 'session-1',
      deletedAt: DateTime.utc(2026, 3, 1),
    );

    final merged = mergeSnapshots(
      _snapshot(sessions: [_session('session-1'), _session('session-2')]),
      _snapshot(deletedSessions: [deletion]),
    );

    expect(merged.sessions.map((session) => session.id), ['session-2']);
    expect(merged.deletedSessions.single.id, 'session-1');
  });

  test('a session only one side has is kept', () {
    final merged = mergeSnapshots(
      _snapshot(sessions: [_session('session-1')]),
      _snapshot(),
    );

    expect(merged.sessions.single.id, 'session-1');
    expect(merged.deletedSessions, isEmpty);
  });

  test('a set removed on one side stays removed', () {
    const squat = SetLog(
      exerciseId: 'squat',
      exerciseName: 'Squat',
      setNumber: 1,
      reps: 5,
    );
    const secondRound = SetLog(
      exerciseId: 'squat',
      exerciseName: 'Squat',
      setNumber: 1,
      reps: 5,
      round: 2,
    );
    final full = _logged('session-1', const [squat, secondRound]);
    final trimmed = _logged('session-1', const [squat]);

    final merged = mergeSnapshots(
      _snapshot(sessions: [trimmed]),
      _snapshot(sessions: [full]),
    );

    expect(merged.sessions.single.setLogs.map((log) => log.round), [1]);
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

  test('newer appearance wins', () {
    final merged = mergeSnapshots(
      _snapshot(skin: 'forest', appearanceUpdatedAt: DateTime.utc(2026, 5, 1)),
      _snapshot(skin: 'sunset', appearanceUpdatedAt: DateTime.utc(2026, 1, 1)),
    );

    expect(merged.skin, 'forest');
    expect(merged.themeMode, 'dark');
  });

  test('a newer home order wins, and a newer edit still wins', () {
    final merged = mergeSnapshots(
      _snapshot(
        workouts: [
          _workout('same', DateTime.utc(2026, 1, 1), 'Old'),
          _workout('other', DateTime.utc(2026, 1, 1), 'Other'),
        ],
        homeOrderUpdatedAt: DateTime.utc(2026, 6, 1),
      ),
      _snapshot(
        workouts: [
          _workout('other', DateTime.utc(2026, 1, 1), 'Other'),
          _workout('same', DateTime.utc(2026, 2, 1), 'New'),
        ],
        homeOrderUpdatedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    expect(merged.workouts.map((workout) => workout.id), ['same', 'other']);
    expect(merged.workouts.first.name, 'New');
    expect(merged.homeOrderUpdatedAt, DateTime.utc(2026, 6, 1));
  });

  test('a workout only the other device has is appended', () {
    final merged = mergeSnapshots(
      _snapshot(
        workouts: [
          _workout('a', DateTime.utc(2026, 1, 1), 'A'),
          _workout('b', DateTime.utc(2026, 1, 1), 'B'),
        ],
        homeOrderUpdatedAt: DateTime.utc(2026, 6, 1),
      ),
      _snapshot(
        workouts: [
          _workout('c', DateTime.utc(2026, 3, 1), 'C'),
          _workout('b', DateTime.utc(2026, 1, 1), 'B'),
          _workout('a', DateTime.utc(2026, 1, 1), 'A'),
        ],
        homeOrderUpdatedAt: DateTime.utc(2026, 1, 1),
      ),
    );

    expect(merged.workouts.map((workout) => workout.id), ['a', 'b', 'c']);
  });

  test('with no home order, workouts stay alphabetical', () {
    final merged = mergeSnapshots(
      _snapshot(
        workouts: [
          _workout('z', DateTime.utc(2026, 1, 1), 'Zebra'),
          _workout('a', DateTime.utc(2026, 1, 1), 'Alpha'),
        ],
      ),
      _snapshot(workouts: [_workout('a', DateTime.utc(2026, 1, 1), 'Alpha')]),
    );

    expect(merged.workouts.map((workout) => workout.name), ['Alpha', 'Zebra']);
    expect(merged.homeOrderUpdatedAt, DateTime.utc(1970));
  });
}

AccountSnapshot _snapshot({
  List<Workout> workouts = const [],
  List<WorkoutDeletion> deletedWorkouts = const [],
  List<CompletedSession> sessions = const [],
  List<WorkoutDeletion> deletedSessions = const [],
  String skin = 'classic',
  DateTime? appearanceUpdatedAt,
  DateTime? homeOrderUpdatedAt,
}) {
  return AccountSnapshot(
    workouts: workouts,
    deletedWorkouts: deletedWorkouts,
    sessions: sessions,
    deletedSessions: deletedSessions,
    themeMode: 'dark',
    skin: skin,
    appearanceUpdatedAt: appearanceUpdatedAt ?? DateTime.utc(1970),
    homeOrderUpdatedAt: homeOrderUpdatedAt ?? DateTime.utc(1970),
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

CompletedSession _logged(String id, List<SetLog> logs) {
  return CompletedSession(
    id: id,
    workoutId: 'workout',
    workoutName: 'Push',
    completedAt: DateTime.utc(2026, 1, 1),
    durationSeconds: 60,
    totalExercises: logs.length,
    setLogs: logs,
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
