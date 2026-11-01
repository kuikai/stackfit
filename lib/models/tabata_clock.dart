import 'exercise.dart';
import 'workout.dart';

/// Classic Tabata recipe and the temporary workout the clock runs.
///
/// The workout is built in memory. It is never written to the workout list.
class TabataClock {
  const TabataClock._();

  static const int classicWorkSeconds = 20;
  static const int classicRestSeconds = 10;
  static const int classicRounds = 8;

  static const int minWorkSeconds = 1;
  static const int maxWorkSeconds = 3600;
  static const int minRestSeconds = 0;
  static const int maxRestSeconds = 600;
  static const int minRounds = 1;
  static const int maxRounds = 99;

  /// Fixed id so this run cannot be mistaken for a workout the user saved.
  static const String workoutId = 'tabata-clock';

  /// One timer exercise. [sets] is the number of work/rest rounds.
  static Workout build({
    int workSeconds = classicWorkSeconds,
    int restSeconds = classicRestSeconds,
    int rounds = classicRounds,
  }) {
    final now = DateTime.utc(2020);
    return Workout(
      id: workoutId,
      name: 'Tabata',
      createdAt: now,
      updatedAt: now,
      exercises: [
        Exercise.timer(
          id: 'tabata-round',
          name: 'Tabata',
          workSeconds: _fit(workSeconds, minWorkSeconds, maxWorkSeconds),
          restSeconds: _fit(restSeconds, minRestSeconds, maxRestSeconds),
          sets: _fit(rounds, minRounds, maxRounds),
        ),
      ],
    );
  }
}

int _fit(int value, int min, int max) {
  if (value < min) {
    return min;
  }
  if (value > max) {
    return max;
  }
  return value;
}
