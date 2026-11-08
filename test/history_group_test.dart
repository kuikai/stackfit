import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/models.dart';

void main() {
  group('groupSessionsByWorkout', () {
    test('keeps one workout together and leaves another apart', () {
      final groups = groupSessionsByWorkout([
        _session(id: 'a1', workoutId: 'test', name: 'test', day: 1),
        _session(id: 'b1', workoutId: 'chest', name: 'Chest', day: 2),
        _session(id: 'a2', workoutId: 'test', name: 'test', day: 5),
      ]);

      expect(groups.map((group) => group.workoutId), ['test', 'chest']);
      expect(groups.first.sessions.map((session) => session.id), ['a2', 'a1']);
      expect(groups.last.sessions.single.id, 'b1');
    });

    test('orders sections by the newest session', () {
      final groups = groupSessionsByWorkout([
        _session(id: 'old', workoutId: 'legs', name: 'Legs', day: 1),
        _session(id: 'new', workoutId: 'push', name: 'Push', day: 9),
        _session(id: 'mid', workoutId: 'legs', name: 'Legs', day: 4),
      ]);

      expect(groups.map((group) => group.workoutId), ['push', 'legs']);
    });

    test('uses the name from the newest session after a rename', () {
      final groups = groupSessionsByWorkout([
        _session(id: 'old', workoutId: 'w', name: 'test', day: 1),
        _session(id: 'new', workoutId: 'w', name: 'Push day', day: 3),
      ]);

      expect(groups.single.name, 'Push day');
      expect(groups.single.sessions.map((session) => session.id), [
        'new',
        'old',
      ]);
    });

    test('same display name with different ids stays two sections', () {
      final groups = groupSessionsByWorkout([
        _session(id: 'a', workoutId: 'one', name: 'test', day: 2),
        _session(id: 'b', workoutId: 'two', name: 'test', day: 4),
      ]);

      expect(groups.map((group) => group.workoutId), ['two', 'one']);
    });
  });

  group('historyChartSeries', () {
    test('skips a single session', () {
      final series = historyChartSeries([
        _session(
          id: 'only',
          workoutId: 'w',
          name: 'test',
          day: 1,
          reps: 8,
          kg: 60,
        ),
      ]);

      expect(series, isNull);
    });

    test('plots kilograms oldest first, keeping the real dates', () {
      final older = _session(
        id: 'old',
        workoutId: 'w',
        name: 'test',
        day: 1,
        reps: 8,
        kg: 60,
      );
      final newer = _session(
        id: 'new',
        workoutId: 'w',
        name: 'test',
        day: 8,
        reps: 10,
        kg: 50,
      );

      final series = historyChartSeries([newer, older]);

      expect(series!.unit, HistoryChartUnit.kilograms);
      expect(series.points.map((point) => point.at), [
        older.completedAt,
        newer.completedAt,
      ]);
      expect(series.points.map((point) => point.value), [480, 500]);
    });

    test('plots reps when the workout has no weights', () {
      final series = historyChartSeries([
        _session(id: 'a', workoutId: 'w', name: 'test', day: 1, reps: 12),
        _session(id: 'b', workoutId: 'w', name: 'test', day: 2, reps: 8),
      ]);

      expect(series!.unit, HistoryChartUnit.reps);
      expect(series.points.map((point) => point.value), [12, 8]);
    });

    test('plots reps when only one session was weighted', () {
      final series = historyChartSeries([
        _session(id: 'a', workoutId: 'w', name: 'test', day: 1, reps: 12),
        _session(
          id: 'b',
          workoutId: 'w',
          name: 'test',
          day: 2,
          reps: 8,
          kg: 40,
        ),
      ]);

      expect(series!.unit, HistoryChartUnit.reps);
      expect(series.points.map((point) => point.value), [12, 8]);
    });
  });
}

CompletedSession _session({
  required String id,
  required String workoutId,
  required String name,
  required int day,
  int reps = 0,
  double? kg,
}) {
  return CompletedSession(
    id: id,
    workoutId: workoutId,
    workoutName: name,
    completedAt: DateTime.utc(2026, 11, day, 18),
    durationSeconds: 60,
    totalExercises: 1,
    setLogs: [
      if (reps > 0)
        SetLog(
          exerciseId: 'lift',
          exerciseName: 'Lift',
          setNumber: 1,
          reps: reps,
          weightKg: kg,
        ),
    ],
  );
}
