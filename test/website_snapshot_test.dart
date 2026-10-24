import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/account_snapshot.dart';
import 'package:stackfit/models/exercise_type.dart';

void main() {
  test('the app can read a workout and session saved by the website', () {
    final snapshot = AccountSnapshot.fromJson({
      'workouts': [
        {
          'id': 'workout-1',
          'name': 'Push day',
          'createdAt': '2026-10-11T18:00:00.000Z',
          'updatedAt': '2026-10-11T18:05:00.000Z',
          'exercises': [
            {
              'id': 'ex-1',
              'name': 'Bench press',
              'type': 'sets',
              'workSeconds': null,
              'restSeconds': 90,
              'sets': 4,
              'reps': 8,
            },
            {
              'id': 'ex-2',
              'name': 'Plank',
              'type': 'timer',
              'workSeconds': 45,
              'restSeconds': 15,
              'sets': 3,
              'reps': null,
            },
          ],
        },
      ],
      'deletedWorkouts': <Map<String, dynamic>>[],
      'sessions': [
        {
          'id': 'session-1',
          'workoutId': 'workout-1',
          'workoutName': 'Push day',
          'completedAt': '2026-10-11T19:00:00.000Z',
          'durationSeconds': 1500,
          'totalExercises': 2,
        },
      ],
      'themeMode': 'system',
      'skin': 'classic',
      'appearanceUpdatedAt': '1970-01-01T00:00:00.000Z',
      'customExercises': [
        {
          'id': 'custom-farmer-carry',
          'name': 'Farmer Carry',
          'category': 'Custom',
          'type': 'sets',
          'workSeconds': null,
          'restSeconds': 90,
          'sets': 4,
          'reps': 6,
        },
      ],
    });

    expect(snapshot.workouts.single.name, 'Push day');
    expect(snapshot.workouts.single.exercises.first.type, ExerciseType.sets);
    expect(snapshot.workouts.single.exercises.last.workSeconds, 45);
    expect(snapshot.sessions.single.durationSeconds, 1500);
    expect(snapshot.themeMode, 'system');
    expect(snapshot.customExercises.single.name, 'Farmer Carry');
    expect(snapshot.customExercises.single.sets, 4);
    expect(snapshot.customExercises.single.preset?.reps, 6);
  });
}
