import '../workout_plan.dart';
import 'plan_helpers.dart';

/// Timed stretching and yoga holds for rest days or after training.
class MobilityPlans {
  MobilityPlans._();

  static const String category = 'Mobility';

  static final List<WorkoutPlan> all = [
    mobility,
  ];

  // Source: yogaphilippines.com 10-minute yoga, loadmuscle.com 15-minute mobility
  static final WorkoutPlan mobility = WorkoutPlan(
    id: 'mobility_sessions',
    name: 'Mobility and Stretching',
    category: category,
    level: 'Beginner',
    description:
        'Two short sessions for rest days or after training. A mild stretch '
        'is fine; stop anything sharp or pinching.',
    equipment: 'Mat',
    days: [
      PlanDay(
        name: '10-min Yoga Flow',
        exercises: [
          PlanExercises.timer('Cat-Cow', work: 45),
          PlanExercises.timer("Child's Pose", work: 45),
          PlanExercises.timer('Downward Dog', work: 30),
          PlanExercises.timer('Low Lunge (left)', work: 30),
          PlanExercises.timer('Low Lunge (right)', work: 30),
          PlanExercises.timer('Standing Forward Fold', work: 30),
          PlanExercises.timer('Tree Pose (left)', work: 25),
          PlanExercises.timer('Tree Pose (right)', work: 25),
          PlanExercises.timer('Seated Forward Fold', work: 45),
          PlanExercises.timer('Supine Twist (left)', work: 40),
          PlanExercises.timer('Supine Twist (right)', work: 40),
          PlanExercises.timer('Savasana', work: 120),
        ],
      ),
      PlanDay(
        name: '15-min Hips and Hamstrings',
        exercises: [
          PlanExercises.timer("World's Greatest Stretch",
              work: 30, rest: 15, rounds: 2),
          PlanExercises.timer('90/90 Hip Stretch',
              work: 30, rest: 15, rounds: 2),
          PlanExercises.timer('Pigeon', work: 30, rest: 15, rounds: 2),
          PlanExercises.timer('Hamstring Stretch',
              work: 30, rest: 15, rounds: 2),
          PlanExercises.timer('Hip Circles', work: 30, rest: 15, rounds: 2),
          PlanExercises.timer('Kneeling Hip Flexor Stretch',
              work: 30, rest: 15, rounds: 2),
        ],
      ),
    ],
  );
}
