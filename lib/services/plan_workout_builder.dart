import '../core/utils.dart';
import '../models/models.dart';

/// Turns read-only plan days into regular [Workout]s with fresh ids.
class PlanWorkoutBuilder {
  PlanWorkoutBuilder._();

  /// Name shown on Home for one plan day. Multi-day plans keep the day name
  /// and put the plan name on [Workout.section] so Home can group them.
  static String workoutName(WorkoutPlan plan, PlanDay day) {
    if (plan.isSingleDay) {
      return plan.name;
    }
    return day.name;
  }

  /// Plan name for multi-day plans; null for a one-off session.
  static String? sectionName(WorkoutPlan plan) {
    if (plan.isSingleDay) {
      return null;
    }
    return plan.name;
  }

  /// Builds one workout from [day]. [newId] is injectable for tests.
  static Workout buildWorkoutFromPlanDay(
    WorkoutPlan plan,
    PlanDay day, {
    String Function() newId = AppUtils.newId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final exercises = day.exercises
        .map((exercise) => exercise.copyWith(id: newId()))
        .toList(growable: false);

    return Workout(
      id: newId(),
      name: workoutName(plan, day),
      exercises: exercises,
      createdAt: timestamp,
      updatedAt: timestamp,
      section: sectionName(plan),
    );
  }

  /// Builds every day of [plan], in order.
  static List<Workout> buildWorkoutsFromPlan(
    WorkoutPlan plan, {
    String Function() newId = AppUtils.newId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return plan.days
        .map(
          (day) => buildWorkoutFromPlanDay(
            plan,
            day,
            newId: newId,
            now: timestamp,
          ),
        )
        .toList(growable: false);
  }
}
