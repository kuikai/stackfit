import '../workout_plan.dart';
import 'combat_and_sport_plans.dart';
import 'endurance_plans.dart';
import 'gym_plans.dart';
import 'home_plans.dart';
import 'mobility_plans.dart';
import 'running_plans.dart';

/// Built-in workout plans shipped with the app (offline, read-only).
class PlanLibrary {
  PlanLibrary._();

  static final List<WorkoutPlan> all = List.unmodifiable([
    ...GymPlans.all,
    ...HomePlans.all,
    ...RunningPlans.all,
    ...EndurancePlans.all,
    ...CombatAndSportPlans.all,
    ...MobilityPlans.all,
  ]);

  /// Categories in the order plans are listed (no sorting, so Gym and Home
  /// stay first for people who do not know where to start).
  static List<String> get categories {
    final seen = <String>[];
    for (final plan in all) {
      if (!seen.contains(plan.category)) {
        seen.add(plan.category);
      }
    }
    return seen;
  }

  static List<WorkoutPlan> byCategory(String category) {
    return all.where((plan) => plan.category == category).toList();
  }

  static WorkoutPlan? byId(String id) {
    for (final plan in all) {
      if (plan.id == id) {
        return plan;
      }
    }
    return null;
  }

  /// Matches name, category, description and day names.
  static List<WorkoutPlan> search(String query) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) {
      return all;
    }
    return all.where((plan) {
      if (plan.name.toLowerCase().contains(lower)) {
        return true;
      }
      if (plan.category.toLowerCase().contains(lower)) {
        return true;
      }
      if (plan.description.toLowerCase().contains(lower)) {
        return true;
      }
      return plan.days.any((day) => day.name.toLowerCase().contains(lower));
    }).toList();
  }
}
