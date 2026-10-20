import 'exercise.dart';
import 'workout.dart';

/// One session inside a built-in plan (for example "Push" or "Week 1").
class PlanDay {
  final String name;
  final List<Exercise> exercises;

  const PlanDay({
    required this.name,
    required this.exercises,
  });

  /// Rough duration, using the same estimate as a saved workout.
  int get estimatedDurationSeconds {
    final probe = Workout(
      id: '',
      name: name,
      exercises: exercises,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
    return probe.estimatedDurationSeconds;
  }
}

/// A built-in, read-only workout plan shipped with the app.
class WorkoutPlan {
  final String id;
  final String name;
  final String category;
  final String level;
  final String description;
  final String equipment;
  final List<PlanDay> days;

  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.category,
    required this.level,
    required this.description,
    required this.equipment,
    required this.days,
  });

  bool get isSingleDay => days.length == 1;

  /// Sum of every day's estimate.
  int get estimatedDurationSeconds {
    var total = 0;
    for (final day in days) {
      total += day.estimatedDurationSeconds;
    }
    return total;
  }

  /// Average length of one session, used on cards.
  int get averageDayDurationSeconds {
    if (days.isEmpty) {
      return 0;
    }
    return estimatedDurationSeconds ~/ days.length;
  }
}
