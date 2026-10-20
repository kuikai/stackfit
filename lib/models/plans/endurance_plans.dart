import '../workout_plan.dart';
import 'plan_helpers.dart';

/// Pool, bike, rower and triathlon sessions.
class EndurancePlans {
  EndurancePlans._();

  static const String swimmingCategory = 'Swimming';
  static const String cyclingCategory = 'Cycling';
  static const String rowingCategory = 'Rowing';
  static const String triathlonCategory = 'Triathlon';

  static final List<WorkoutPlan> all = [
    swimSessions,
    cyclingIntervals,
    rowingIntervals,
    triathlonBrick,
  ];

  // Source: aquaticglee.com/beginner-swim-workouts
  // Distance pieces are set based: tap Done after each length or repeat.
  static final WorkoutPlan swimSessions = WorkoutPlan(
    id: 'swimming_beginner_sessions',
    name: 'Pool Sessions 500 to 1500m',
    category: swimmingCategory,
    level: 'Beginner',
    description:
        'Three pool sessions that build from 500m to 1500m. Tap Done after '
        'each repeat; the rest timer runs between them.',
    equipment: 'Pool, kickboard, pull buoy',
    days: [
      PlanDay(
        name: '500m',
        exercises: [
          PlanExercises.sets('Warm-up 25m easy', sets: 4, rest: 30),
          PlanExercises.sets('Kick 25m', sets: 4, rest: 30),
          PlanExercises.sets('Freestyle 25m moderate', sets: 10, rest: 30),
          PlanExercises.sets('Cool-down 25m easy', sets: 2, rest: 20),
        ],
      ),
      PlanDay(
        name: '1000m',
        exercises: [
          PlanExercises.sets('Warm-up 200m easy', sets: 1, rest: 30),
          PlanExercises.sets('Drill 50m (25 drill + 25 swim)',
              sets: 4, rest: 30),
          PlanExercises.sets('Freestyle 100m moderate', sets: 3, rest: 60),
          PlanExercises.sets('Pull 50m', sets: 4, rest: 30),
          PlanExercises.sets('Cool-down 100m easy', sets: 1, rest: 0),
        ],
      ),
      PlanDay(
        name: '1500m',
        exercises: [
          PlanExercises.sets('Warm-up 300m easy', sets: 1, rest: 30),
          PlanExercises.sets('Drill 50m (25 drill + 25 swim)',
              sets: 4, rest: 20),
          PlanExercises.sets('Freestyle 200m moderate', sets: 2, rest: 45),
          PlanExercises.sets('Freestyle 50m strong', sets: 4, rest: 30),
          PlanExercises.sets('Pull 200m easy', sets: 1, rest: 30),
          PlanExercises.sets('Kick 25m', sets: 4, rest: 20),
          PlanExercises.sets('Cool-down 100m easy', sets: 1, rest: 0),
        ],
      ),
    ],
  );

  // Source: veloworkout.com sweet spot, rouvy.com, velosurance.com 4x4
  static final WorkoutPlan cyclingIntervals = WorkoutPlan(
    id: 'cycling_intervals',
    name: 'Indoor Cycling Intervals',
    category: cyclingCategory,
    level: 'Intermediate',
    description:
        'Three trainer sessions. Sweet spot is a strong but steady effort; '
        'the 4x4 is hard, about 8 to 9 out of 10.',
    equipment: 'Bike and trainer, or a quiet road',
    days: [
      PlanDay(
        name: 'Sweet Spot 30 min',
        exercises: [
          PlanExercises.block('Easy Spin', 10),
          PlanExercises.timer('Sweet Spot (then easy spin)',
              work: 180, rest: 180, rounds: 4),
          PlanExercises.block('Easy Spin', 10),
        ],
      ),
      PlanDay(
        name: 'Sweet Spot 3x10',
        exercises: [
          PlanExercises.block('Easy Spin', 10),
          PlanExercises.timer('Sweet Spot (then easy spin)',
              work: 600, rest: 300, rounds: 3),
          PlanExercises.block('Easy Spin', 5),
        ],
      ),
      PlanDay(
        name: 'Norwegian 4x4',
        exercises: [
          PlanExercises.block('Easy Spin', 10),
          PlanExercises.timer('VO2 Interval (then easy spin)',
              work: 240, rest: 180, rounds: 4),
          PlanExercises.block('Easy Spin', 5),
        ],
      ),
    ],
  );

  // Source: techfitnesslab.com HIIT rowing, rowingmachineworkouts.com
  static final WorkoutPlan rowingIntervals = WorkoutPlan(
    id: 'rowing_intervals',
    name: 'Rowing Machine Intervals',
    category: rowingCategory,
    level: 'Beginner',
    description:
        'Three erg sessions. Keep the hard pieces controlled and drive with '
        'the legs first.',
    equipment: 'Rowing machine',
    days: [
      PlanDay(
        name: '20-min Intervals',
        exercises: [
          PlanExercises.block('Easy Row', 3),
          PlanExercises.timer('Hard Row (then easy)',
              work: 20, rest: 40, rounds: 8),
          PlanExercises.block('Steady Row', 5),
          PlanExercises.block('Easy Row', 4),
        ],
      ),
      PlanDay(
        name: '30-min Intervals',
        exercises: [
          PlanExercises.block('Easy Row', 3),
          PlanExercises.timer('Hard Row (then easy)',
              work: 60, rest: 60, rounds: 10),
          PlanExercises.block('Steady Row', 5),
          PlanExercises.block('Easy Row', 2),
        ],
      ),
      PlanDay(
        name: '4x500m',
        exercises: [
          PlanExercises.block('Easy Row', 5),
          PlanExercises.sets('500m Row', sets: 4, rest: 120),
          PlanExercises.block('Easy Row', 3),
        ],
      ),
    ],
  );

  // Source: coachray.nz beginner sprint/olympic brick
  static final WorkoutPlan triathlonBrick = WorkoutPlan(
    id: 'triathlon_brick',
    name: 'First Brick',
    category: triathlonCategory,
    level: 'Beginner',
    description:
        'A 30-minute ride that builds through three efforts, then straight '
        'into a 10-minute easy run. Finish with stretching.',
    equipment: 'Bike, running shoes',
    days: [
      PlanDay(
        name: 'Bike to run',
        exercises: [
          PlanExercises.block('Bike easy', 10),
          PlanExercises.block('Bike moderate', 15),
          PlanExercises.block('Bike hard', 5),
          PlanExercises.block('Easy Run', 10),
          PlanExercises.block('Stretch', 10),
        ],
      ),
    ],
  );
}
