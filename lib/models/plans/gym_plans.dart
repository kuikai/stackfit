import '../workout_plan.dart';
import 'plan_helpers.dart';

/// Barbell and machine plans for a commercial gym.
class GymPlans {
  GymPlans._();

  static const String category = 'Gym';

  static const int _mainLiftRest = 180;
  static const int _accessoryRest = 90;

  static final List<WorkoutPlan> all = [
    fullBody5x5,
    pushPullLegs,
    upperLower,
    broSplit,
  ];

  // Source: stronglifts.com/stronglifts-5x5/workout-program
  static final WorkoutPlan fullBody5x5 = WorkoutPlan(
    id: 'gym_full_body_5x5',
    name: 'Beginner Full Body 5x5',
    category: category,
    level: 'Beginner',
    description:
        'Three sessions a week, alternating A and B. Squat every session, '
        'add a little weight each time you complete all reps.',
    equipment: 'Barbell, rack, bench',
    days: [
      PlanDay(
        name: 'Workout A',
        exercises: [
          PlanExercises.sets('Squat', sets: 5, reps: 5, rest: _mainLiftRest),
          PlanExercises.sets('Bench Press',
              sets: 5, reps: 5, rest: _mainLiftRest),
          PlanExercises.sets('Barbell Row',
              sets: 5, reps: 5, rest: _mainLiftRest),
        ],
      ),
      PlanDay(
        name: 'Workout B',
        exercises: [
          PlanExercises.sets('Squat', sets: 5, reps: 5, rest: _mainLiftRest),
          PlanExercises.sets('Overhead Press',
              sets: 5, reps: 5, rest: _mainLiftRest),
          PlanExercises.sets('Deadlift',
              sets: 1, reps: 5, rest: _mainLiftRest),
        ],
      ),
    ],
  );

  // Source: trackist.me/workout-plans/push-pull-legs-3-day, easyreps.app
  static final WorkoutPlan pushPullLegs = WorkoutPlan(
    id: 'gym_push_pull_legs',
    name: 'Push / Pull / Legs',
    category: category,
    level: 'Beginner',
    description:
        'Three days with a rest day between. Push on Monday, pull on '
        'Wednesday, legs on Friday.',
    equipment: 'Barbell, dumbbells, cables, machines',
    days: [
      PlanDay(
        name: 'Push',
        exercises: [
          PlanExercises.sets('Bench Press',
              sets: 3, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Seated Dumbbell Shoulder Press',
              sets: 3, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Incline Dumbbell Press',
              sets: 3, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Lateral Raise',
              sets: 3, reps: 15, rest: _accessoryRest),
          PlanExercises.sets('Triceps Pushdown',
              sets: 3, reps: 12, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Pull',
        exercises: [
          PlanExercises.sets('Lat Pulldown',
              sets: 3, reps: 10, rest: _mainLiftRest),
          PlanExercises.sets('Barbell Row',
              sets: 3, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Seated Cable Row',
              sets: 2, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Face Pull',
              sets: 3, reps: 15, rest: _accessoryRest),
          PlanExercises.sets('Dumbbell Curl',
              sets: 3, reps: 12, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Legs',
        exercises: [
          PlanExercises.sets('Squat', sets: 3, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Romanian Deadlift',
              sets: 3, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Leg Press',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Leg Curl',
              sets: 2, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Calf Raise',
              sets: 3, reps: 15, rest: _accessoryRest),
        ],
      ),
    ],
  );

  // Source: nishaana.com/blog/4-day-split-guide
  static final WorkoutPlan upperLower = WorkoutPlan(
    id: 'gym_upper_lower',
    name: 'Upper / Lower',
    category: category,
    level: 'Intermediate',
    description:
        'Four days: Upper A, Lower A, Upper B, Lower B. Every muscle is '
        'trained twice a week. Run Mon, Tue, Thu, Fri.',
    equipment: 'Barbell, dumbbells, cables, machines',
    days: [
      PlanDay(
        name: 'Upper A',
        exercises: [
          PlanExercises.sets('Bench Press',
              sets: 4, reps: 6, rest: _mainLiftRest),
          PlanExercises.sets('Barbell Row',
              sets: 4, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Overhead Press',
              sets: 3, reps: 8, rest: _accessoryRest),
          PlanExercises.sets('Lat Pulldown',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Dumbbell Curl',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Triceps Pushdown',
              sets: 3, reps: 12, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Lower A',
        exercises: [
          PlanExercises.sets('Squat', sets: 4, reps: 6, rest: _mainLiftRest),
          PlanExercises.sets('Romanian Deadlift',
              sets: 3, reps: 10, rest: _mainLiftRest),
          PlanExercises.sets('Leg Press',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Leg Curl',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Calf Raise',
              sets: 4, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Leg Raises',
              sets: 3, reps: 12, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Upper B',
        exercises: [
          PlanExercises.sets('Incline Dumbbell Press',
              sets: 4, reps: 10, rest: _mainLiftRest),
          PlanExercises.sets('Pull-ups',
              sets: 4, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Dumbbell Shoulder Press',
              sets: 3, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Seated Cable Row',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Lateral Raise',
              sets: 3, reps: 15, rest: _accessoryRest),
          PlanExercises.sets('Hammer Curl',
              sets: 3, reps: 12, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Lower B',
        exercises: [
          PlanExercises.sets('Hip Thrust',
              sets: 4, reps: 10, rest: _mainLiftRest),
          PlanExercises.sets('Front Squat',
              sets: 3, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Leg Extension',
              sets: 3, reps: 15, rest: _accessoryRest),
          PlanExercises.sets('Leg Curl',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Calf Raise',
              sets: 4, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Cable Crunch',
              sets: 3, reps: 15, rest: _accessoryRest),
        ],
      ),
    ],
  );

  // Source: trackist.me/workout-plans/bro-split, legionathletics.com/bro-split
  static final WorkoutPlan broSplit = WorkoutPlan(
    id: 'gym_bro_split',
    name: 'Bro Split',
    category: category,
    level: 'Intermediate',
    description:
        'One body part a day, five days a week: chest, back, shoulders, arms, '
        'legs. Weekend off.',
    equipment: 'Barbell, dumbbells, cables, machines',
    days: [
      PlanDay(
        name: 'Chest',
        exercises: [
          PlanExercises.sets('Bench Press',
              sets: 4, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Incline Dumbbell Press',
              sets: 4, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Dips', sets: 3, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Cable Fly',
              sets: 3, reps: 15, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Back',
        exercises: [
          PlanExercises.sets('Lat Pulldown',
              sets: 4, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Barbell Row',
              sets: 4, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Seated Cable Row',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('One-arm Dumbbell Row',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Face Pull',
              sets: 3, reps: 15, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Shoulders',
        exercises: [
          PlanExercises.sets('Overhead Press',
              sets: 4, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Dumbbell Shoulder Press',
              sets: 3, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Lateral Raise',
              sets: 4, reps: 15, rest: _accessoryRest),
          PlanExercises.sets('Rear Delt Fly',
              sets: 3, reps: 15, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Arms',
        exercises: [
          PlanExercises.sets('Close-grip Bench Press',
              sets: 3, reps: 10, rest: _mainLiftRest),
          PlanExercises.sets('Barbell Curl',
              sets: 3, reps: 10, rest: _accessoryRest),
          PlanExercises.sets('Triceps Pushdown',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Incline Dumbbell Curl',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Overhead Triceps Extension',
              sets: 3, reps: 15, rest: _accessoryRest),
          PlanExercises.sets('Hammer Curl',
              sets: 2, reps: 12, rest: _accessoryRest),
        ],
      ),
      PlanDay(
        name: 'Legs',
        exercises: [
          PlanExercises.sets('Squat', sets: 4, reps: 8, rest: _mainLiftRest),
          PlanExercises.sets('Romanian Deadlift',
              sets: 3, reps: 10, rest: _mainLiftRest),
          PlanExercises.sets('Leg Press',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Leg Curl',
              sets: 3, reps: 12, rest: _accessoryRest),
          PlanExercises.sets('Calf Raise',
              sets: 4, reps: 15, rest: _accessoryRest),
        ],
      ),
    ],
  );
}
