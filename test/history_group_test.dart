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

  group('historyChartExercises', () {
    test('lists the newest session first, then older exercises', () {
      final exercises = historyChartExercises([
        _session(
          id: 'old',
          workoutId: 'w',
          name: 'test',
          day: 1,
          logs: const [
            SetLog(
              exerciseId: 'press',
              exerciseName: 'Press',
              setNumber: 1,
              reps: 8,
            ),
            SetLog(
              exerciseId: 'squat',
              exerciseName: 'Squat old',
              setNumber: 1,
              reps: 5,
              weightKg: 40,
            ),
          ],
        ),
        _session(
          id: 'new',
          workoutId: 'w',
          name: 'test',
          day: 8,
          logs: const [
            SetLog(
              exerciseId: 'squat',
              exerciseName: 'Squat',
              setNumber: 1,
              reps: 5,
              weightKg: 50,
            ),
            SetLog(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              setNumber: 1,
              reps: 8,
              weightKg: 60,
            ),
          ],
        ),
      ]);

      expect(exercises.map((exercise) => exercise.id), [
        'squat',
        'bench',
        'press',
      ]);
      expect(exercises.first.name, 'Squat');
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

    test('counts sets for the whole workout', () {
      final series = historyChartSeries([
        _session(
          id: 'a',
          workoutId: 'w',
          name: 'test',
          day: 1,
          logs: const [
            SetLog(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              setNumber: 1,
              reps: 8,
              weightKg: 60,
            ),
            SetLog(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              setNumber: 2,
              reps: 8,
              weightKg: 60,
            ),
          ],
        ),
        _session(
          id: 'b',
          workoutId: 'w',
          name: 'test',
          day: 2,
          logs: const [
            SetLog(
              exerciseId: 'bench',
              exerciseName: 'Bench',
              setNumber: 1,
              reps: 6,
              weightKg: 60,
            ),
          ],
        ),
      ], unit: HistoryChartUnit.sets);

      expect(series!.unit, HistoryChartUnit.sets);
      expect(series.points.map((point) => point.value), [2, 1]);
    });

    test('keeps kilograms at zero when nothing was weighted', () {
      final series = historyChartSeries([
        _session(id: 'a', workoutId: 'w', name: 'test', day: 1, reps: 12),
        _session(id: 'b', workoutId: 'w', name: 'test', day: 2, reps: 8),
      ]);

      expect(series!.unit, HistoryChartUnit.kilograms);
      expect(series.points.map((point) => point.value), [0, 0]);
    });

    test('plots one exercise and drops a session that skipped it', () {
      final withBench = _session(
        id: 'with',
        workoutId: 'w',
        name: 'test',
        day: 1,
        logs: const [
          SetLog(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            setNumber: 1,
            reps: 8,
            weightKg: 20,
          ),
          SetLog(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            setNumber: 1,
            reps: 8,
            weightKg: 20,
            round: 2,
          ),
          SetLog(
            exerciseId: 'row',
            exerciseName: 'Row',
            setNumber: 1,
            reps: 10,
            weightKg: 30,
          ),
        ],
      );
      final skipped = _session(
        id: 'skip',
        workoutId: 'w',
        name: 'test',
        day: 4,
        logs: const [
          SetLog(
            exerciseId: 'row',
            exerciseName: 'Row',
            setNumber: 1,
            reps: 10,
            weightKg: 30,
          ),
        ],
      );
      final again = _session(
        id: 'again',
        workoutId: 'w',
        name: 'test',
        day: 8,
        logs: const [
          SetLog(
            exerciseId: 'bench',
            exerciseName: 'Bench',
            setNumber: 1,
            reps: 5,
            weightKg: 40,
          ),
        ],
      );

      final kilograms = historyChartSeries([
        again,
        skipped,
        withBench,
      ], exerciseId: 'bench');
      final sets = historyChartSeries(
        [again, skipped, withBench],
        exerciseId: 'bench',
        unit: HistoryChartUnit.sets,
      );

      expect(kilograms!.points.map((point) => point.at), [
        withBench.completedAt,
        again.completedAt,
      ]);
      expect(kilograms.points.map((point) => point.value), [320, 200]);
      expect(sets!.points.map((point) => point.value), [2, 1]);
    });

    test('plots the longest hold when the workout is holds', () {
      final series = historyChartSeries([
        _session(
          id: 'a',
          workoutId: 'w',
          name: 'Plank',
          day: 1,
          logs: const [
            SetLog(
              exerciseId: 'plank',
              exerciseName: 'Plank',
              setNumber: 1,
              reps: 0,
              heldSeconds: 40,
            ),
            SetLog(
              exerciseId: 'plank',
              exerciseName: 'Plank',
              setNumber: 2,
              reps: 0,
              heldSeconds: 50,
            ),
          ],
        ),
        _session(
          id: 'b',
          workoutId: 'w',
          name: 'Plank',
          day: 2,
          logs: const [
            SetLog(
              exerciseId: 'plank',
              exerciseName: 'Plank',
              setNumber: 1,
              reps: 0,
              heldSeconds: 65,
            ),
          ],
        ),
      ], unit: HistoryChartUnit.seconds);

      expect(series!.unit, HistoryChartUnit.seconds);
      expect(series.points.map((point) => point.value), [50, 65]);
    });

    test('skips an exercise logged on only one day', () {
      final series = historyChartSeries([
        _session(
          id: 'a',
          workoutId: 'w',
          name: 'test',
          day: 1,
          reps: 8,
          kg: 40,
        ),
        _session(
          id: 'b',
          workoutId: 'w',
          name: 'test',
          day: 2,
          logs: const [
            SetLog(
              exerciseId: 'other',
              exerciseName: 'Other',
              setNumber: 1,
              reps: 8,
              weightKg: 40,
            ),
          ],
        ),
      ], exerciseId: 'lift');

      expect(series, isNull);
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
  List<SetLog>? logs,
}) {
  return CompletedSession(
    id: id,
    workoutId: workoutId,
    workoutName: name,
    completedAt: DateTime.utc(2026, 11, day, 18),
    durationSeconds: 60,
    totalExercises: 1,
    setLogs:
        logs ??
        [
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
