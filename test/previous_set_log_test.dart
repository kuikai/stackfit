import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/services/previous_set_log.dart';

void main() {
  group('previousLogsForExercise', () {
    test('uses this workout only', () {
      final logs = previousLogsForExercise(
        sessions: [
          _session(
            id: 'other',
            workoutId: 'other-day',
            setLogs: [_log(reps: 12)],
          ),
          _session(id: 'mine', workoutId: 'push', setLogs: [_log(reps: 8)]),
        ],
        workoutId: 'push',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
      );

      expect(logs.single.reps, 8);
    });

    test('uses the newest session that logged this exercise', () {
      final logs = previousLogsForExercise(
        sessions: [
          _session(
            id: 'new',
            workoutId: 'push',
            setLogs: [
              _log(setNumber: 1, reps: 8, weightKg: 60),
              _log(setNumber: 2, reps: 6, weightKg: 60),
              _log(
                exerciseId: 'row',
                exerciseName: 'Row',
                setNumber: 1,
                reps: 10,
              ),
            ],
          ),
          _session(
            id: 'old',
            workoutId: 'push',
            setLogs: [_log(reps: 5, weightKg: 50)],
          ),
        ],
        workoutId: 'push',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
      );

      expect(logs.map((log) => log.setNumber), [1, 2]);
      expect(logs.map((log) => log.reps), [8, 6]);
      expect(logs.first.weightKg, 60);
    });

    test('skips a newer session that did not log this exercise', () {
      final logs = previousLogsForExercise(
        sessions: [
          _session(
            id: 'new',
            workoutId: 'push',
            setLogs: [_log(exerciseId: 'row', exerciseName: 'Row', reps: 10)],
          ),
          _session(id: 'old', workoutId: 'push', setLogs: [_log(reps: 7)]),
        ],
        workoutId: 'push',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
      );

      expect(logs.single.reps, 7);
    });

    test('matches the same circuit round', () {
      final sessions = [
        _session(
          id: 'new',
          workoutId: 'circuit',
          setLogs: [_log(round: 1, reps: 9)],
        ),
        _session(
          id: 'old',
          workoutId: 'circuit',
          setLogs: [_log(round: 1, reps: 8), _log(round: 2, reps: 6)],
        ),
      ];

      final roundTwo = previousLogsForExercise(
        sessions: sessions,
        workoutId: 'circuit',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        round: 2,
      );
      final roundOne = previousLogsForExercise(
        sessions: sessions,
        workoutId: 'circuit',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
      );

      expect(roundTwo.single.reps, 6);
      expect(roundOne.single.reps, 9);
    });

    test('prefers the exercise id over a newer session with the same name', () {
      final logs = previousLogsForExercise(
        sessions: [
          _session(
            id: 'new',
            workoutId: 'push',
            setLogs: [
              _log(exerciseId: 'other', exerciseName: 'Bench Press', reps: 10),
            ],
          ),
          _session(id: 'old', workoutId: 'push', setLogs: [_log(reps: 8)]),
        ],
        workoutId: 'push',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
      );

      expect(logs.single.reps, 8);
    });

    test('uses the name when this id was never logged', () {
      final logs = previousLogsForExercise(
        sessions: [
          _session(
            id: 'old',
            workoutId: 'push',
            setLogs: [_log(exerciseId: 'old-bench', reps: 8, weightKg: 55)],
          ),
        ],
        workoutId: 'push',
        exerciseId: 'new-bench',
        exerciseName: 'Bench Press',
      );

      expect(logs.single.reps, 8);
      expect(logs.single.weightKg, 55);
    });

    test('does not use the name when the id was logged on another round', () {
      final logs = previousLogsForExercise(
        sessions: [
          _session(
            id: 'once',
            workoutId: 'circuit',
            setLogs: [
              _log(round: 1, reps: 8),
              _log(
                exerciseId: 'other',
                exerciseName: 'Bench Press',
                round: 2,
                reps: 10,
              ),
            ],
          ),
        ],
        workoutId: 'circuit',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
        round: 2,
      );

      expect(logs, isEmpty);
    });

    test('fills the add fields from that set last time', () {
      final previous = [
        _log(setNumber: 1, reps: 8, weightKg: 7.5),
        _log(setNumber: 2, reps: 6, weightKg: 22.5),
        _log(setNumber: 3, reps: 8),
      ];

      final first = startingEntryForSet(
        previousLogs: previous,
        setNumber: 1,
        plannedReps: 10,
        sessionWeightKg: 40,
      );
      final second = startingEntryForSet(
        previousLogs: previous,
        setNumber: 2,
        plannedReps: 10,
        sessionWeightKg: 40,
      );
      final bodyweight = startingEntryForSet(
        previousLogs: previous,
        setNumber: 3,
        plannedReps: 10,
        sessionWeightKg: 40,
      );

      expect(first.reps, 8);
      expect(first.weightKg, 7.5);
      expect(second.reps, 6);
      expect(second.weightKg, 22.5);
      expect(bodyweight.reps, 8);
      expect(bodyweight.weightKg, 0);
    });

    test('uses the plan and this session when that set has no last time', () {
      final start = startingEntryForSet(
        previousLogs: [_log(setNumber: 1, reps: 8, weightKg: 20)],
        setNumber: 2,
        plannedReps: 10,
        sessionWeightKg: 20,
      );

      expect(start.reps, 10);
      expect(start.weightKg, 20);
    });

    test('is empty when nothing was logged', () {
      final logs = previousLogsForExercise(
        sessions: [
          _session(id: 'empty', workoutId: 'push'),
          _session(id: 'other', workoutId: 'legs', setLogs: [_log(reps: 5)]),
        ],
        workoutId: 'push',
        exerciseId: 'bench',
        exerciseName: 'Bench Press',
      );

      expect(logs, isEmpty);
    });
  });
}

CompletedSession _session({
  required String id,
  required String workoutId,
  List<SetLog> setLogs = const [],
}) {
  return CompletedSession(
    id: id,
    workoutId: workoutId,
    workoutName: 'Day',
    completedAt: DateTime(2026),
    durationSeconds: 60,
    totalExercises: 1,
    setLogs: setLogs,
  );
}

SetLog _log({
  String exerciseId = 'bench',
  String exerciseName = 'Bench Press',
  int setNumber = 1,
  int reps = 8,
  double? weightKg,
  int round = 1,
}) {
  return SetLog(
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    setNumber: setNumber,
    reps: reps,
    weightKg: weightKg,
    round: round,
  );
}
