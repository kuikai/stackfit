import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/services/workout_session_controller.dart';

Workout _benchWorkout() {
  return Workout(
    id: 'w1',
    name: 'Bench day',
    exercises: [
      Exercise.sets(
        id: 'e1',
        name: 'Bench Press',
        sets: 2,
        reps: 8,
        restSeconds: 60,
      ),
      Exercise.sets(id: 'e2', name: 'Push-ups', sets: 1, restSeconds: 0),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

WorkoutSessionController _controller(Workout workout) {
  return WorkoutSessionController(
    workout: workout,
    onWorkFinished: () {},
    onRestFinished: () {},
    onWorkoutFinished: () {},
  );
}

void main() {
  group('WorkoutSessionController set logging', () {
    test('records reps per completed set and defaults to planned reps', () {
      final controller = _controller(_benchWorkout());
      addTearDown(controller.disposeController);

      controller.completeSet(repsDone: 7);
      expect(controller.setLogs, hasLength(1));
      expect(controller.setLogs.single.exerciseName, 'Bench Press');
      expect(controller.setLogs.single.setNumber, 1);
      expect(controller.setLogs.single.reps, 7);

      // Rest is running after set 1; the log can still be corrected.
      expect(controller.restingSetLog?.reps, 7);
      controller.updateLastSetReps(6);
      expect(controller.setLogs.single.reps, 6);

      controller.skipRest();
      controller.completeSet();
      expect(controller.setLogs, hasLength(2));
      expect(controller.setLogs.last.setNumber, 2);
      expect(controller.setLogs.last.reps, 8);

      controller.skipRest();
      controller.completeSet(repsDone: 15);
      expect(controller.setLogs.last.exerciseName, 'Push-ups');
      expect(controller.setLogs.last.reps, 15);
      expect(controller.state.isComplete, isTrue);
    });

    test('records weight and lets any set be corrected', () {
      final controller = _controller(_benchWorkout());
      addTearDown(controller.disposeController);

      controller.completeSet(repsDone: 8, weightKg: 60);
      expect(controller.setLogs.single.weightKg, 60);
      expect(controller.setLogs.single.hasWeight, isTrue);

      controller.skipRest();
      controller.completeSet(repsDone: 6, weightKg: 62.5);

      // Correct set 1 only; set 2 is untouched.
      controller.updateSetLog('e1', 1, weightKg: 65);
      expect(controller.setLogs.first.weightKg, 65);
      expect(controller.setLogs.first.reps, 8);
      expect(controller.setLogs.last.weightKg, 62.5);

      controller.updateSetLog('e1', 2, reps: 5);
      expect(controller.setLogs.last.reps, 5);
      expect(controller.setLogs.last.weightKg, 62.5);

      // Negative values and unknown sets are ignored.
      controller.updateSetLog('e1', 1, weightKg: -5);
      controller.updateSetLog('e1', 9, reps: 1);
      expect(controller.setLogs.first.weightKg, 65);
      expect(controller.currentExerciseLogs, hasLength(2));
    });

    test('restart clears logs', () {
      final controller = _controller(_benchWorkout());
      addTearDown(controller.disposeController);

      controller.completeSet(repsDone: 5);
      expect(controller.setLogs, isNotEmpty);
      controller.restart();
      expect(controller.setLogs, isEmpty);
    });

    test('ignores negative reps and does nothing with no logs', () {
      final controller = _controller(_benchWorkout());
      addTearDown(controller.disposeController);

      controller.updateLastSetReps(3);
      expect(controller.setLogs, isEmpty);
      controller.completeSet(repsDone: 5);
      controller.updateLastSetReps(-1);
      expect(controller.setLogs.single.reps, 5);
    });
  });

  group('CompletedSession set logs', () {
    test('round-trips through JSON', () {
      final session = CompletedSession(
        id: 's1',
        workoutId: 'w1',
        workoutName: 'Bench day',
        completedAt: DateTime.utc(2026, 10, 13, 18),
        durationSeconds: 600,
        totalExercises: 2,
        setLogs: const [
          SetLog(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            setNumber: 1,
            reps: 8,
            weightKg: 60,
          ),
          SetLog(
            exerciseId: 'e1',
            exerciseName: 'Bench Press',
            setNumber: 2,
            reps: 6,
          ),
        ],
      );

      final restored = CompletedSession.fromJson(session.toJson());
      expect(restored.setLogs, hasLength(2));
      expect(restored.setLogs.first.weightKg, 60);
      expect(restored.setLogs.last.reps, 6);
      expect(restored.setLogs.last.weightKg, isNull);
      expect(restored.setLogs.last.toJson().containsKey('weightKg'), isFalse);
      expect(restored.totalRepsLogged, 14);
      expect(restored.totalVolumeKg, 480);
    });

    test('formats kg and short labels', () {
      expect(SetLog.formatKg(60), '60');
      expect(SetLog.formatKg(62.5), '62.5');
      const bodyweight = SetLog(
        exerciseId: 'e',
        exerciseName: 'Push-ups',
        setNumber: 1,
        reps: 12,
      );
      const weighted = SetLog(
        exerciseId: 'e',
        exerciseName: 'Squat',
        setNumber: 1,
        reps: 5,
        weightKg: 102.5,
      );
      expect(bodyweight.shortLabel, '12');
      expect(weighted.shortLabel, '5×102.5');
    });

    test('old sessions without setLogs still load', () {
      final restored = CompletedSession.fromJson({
        'id': 's1',
        'workoutId': 'w1',
        'workoutName': 'Old',
        'completedAt': '2026-01-01T10:00:00.000Z',
        'durationSeconds': 60,
        'totalExercises': 1,
      });
      expect(restored.setLogs, isEmpty);
      expect(restored.hasSetLogs, isFalse);
      expect(restored.toJson().containsKey('setLogs'), isFalse);
    });
  });
}
