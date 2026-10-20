import '../workout_plan.dart';
import 'plan_helpers.dart';

/// Boxing rounds, jump rope and field-sport conditioning.
class CombatAndSportPlans {
  CombatAndSportPlans._();

  static const String boxingCategory = 'Boxing';
  static const String jumpRopeCategory = 'Jump Rope';
  static const String soccerCategory = 'Soccer';

  static const int _round = 180;
  static const int _roundRest = 60;

  static final List<WorkoutPlan> all = [
    boxingRounds,
    jumpRope,
    soccerConditioning,
  ];

  // Source: jabsterboxing.com, boxingwiki.org 20-minute heavy bag HIIT
  static final WorkoutPlan boxingRounds = WorkoutPlan(
    id: 'boxing_rounds',
    name: 'Boxing Rounds',
    category: boxingCategory,
    level: 'Beginner',
    description:
        'Three-minute rounds with a minute of rest. Start with shadow '
        'boxing; add the bag once your punches are clean.',
    equipment: 'Timer; wraps, gloves and a heavy bag for day 2',
    days: [
      PlanDay(
        name: 'Shadow Boxing',
        exercises: [
          PlanExercises.block('Jump Rope', 2),
          PlanExercises.timer('Round 1 · Jab only',
              work: _round, rest: _roundRest),
          PlanExercises.timer('Round 2 · Jab-Cross',
              work: _round, rest: _roundRest),
          PlanExercises.timer('Round 3 · 1-2-3',
              work: _round, rest: _roundRest),
          PlanExercises.timer('Round 4 · Free round', work: _round),
        ],
      ),
      PlanDay(
        name: 'Heavy Bag',
        exercises: [
          PlanExercises.block('Shadow Boxing', 3),
          PlanExercises.timer('Round 1 · Jab', work: _round, rest: _roundRest),
          PlanExercises.timer('Round 2 · Jab-Cross',
              work: _round, rest: _roundRest),
          PlanExercises.timer('Round 3 · Combinations',
              work: _round, rest: _roundRest),
          PlanExercises.timer('Round 4 · Power',
              work: _round, rest: _roundRest),
          PlanExercises.timer('Round 5 · Speed',
              work: _round, rest: _roundRest),
          PlanExercises.timer('Round 6 · Put it together',
              work: _round, rest: _roundRest),
          PlanExercises.block('Cool-down Shadow Boxing', 2),
        ],
      ),
    ],
  );

  // Source: realsimple.com 15-minute jump rope, crossrope.com beginner
  static final WorkoutPlan jumpRope = WorkoutPlan(
    id: 'jump_rope_sessions',
    name: 'Jump Rope',
    category: jumpRopeCategory,
    level: 'Beginner',
    description:
        'Two skipping sessions. Land softly on the balls of your feet; if a '
        'full minute is too much, cut the work time in half.',
    equipment: 'Jump rope',
    days: [
      PlanDay(
        name: '15-min Intervals',
        exercises: [
          PlanExercises.timer('Jump Rope', work: 60, rest: 30, rounds: 10),
          PlanExercises.block('Cool-down Stretch', 2),
        ],
      ),
      PlanDay(
        name: 'Triple Tabata',
        exercises: [
          PlanExercises.timer('Alternate Foot Jump',
              work: 20, rest: 10, rounds: 8),
          PlanExercises.timer('Recover', work: 60),
          PlanExercises.timer('Mountain Climbers',
              work: 20, rest: 10, rounds: 8),
          PlanExercises.timer('Recover', work: 60),
          PlanExercises.timer('Alternate Foot Jump',
              work: 20, rest: 10, rounds: 8),
        ],
      ),
    ],
  );

  // Source: practiceplan.app soccer conditioning, soccercoachlab.com 30-15
  static final WorkoutPlan soccerConditioning = WorkoutPlan(
    id: 'soccer_conditioning',
    name: 'Soccer Conditioning',
    category: soccerCategory,
    level: 'Intermediate',
    description:
        'Short bursts with quick recovery. Set cones at 5, 10 and 15 metres '
        'for the shuttles and tap Done after each one.',
    equipment: 'Cones, a ball if you like',
    days: [
      PlanDay(
        name: 'Field session',
        exercises: [
          PlanExercises.block('Warm-up Jog and Ball Touches', 8),
          PlanExercises.sets('Shuttle Run 5-10-15', sets: 3, rest: 60),
          PlanExercises.timer('Sprint (then walk back)',
              work: 20, rest: 40, rounds: 6),
          PlanExercises.timer('30-15 Ball Work',
              work: 30, rest: 15, rounds: 8),
          PlanExercises.block('Cool-down Walk', 2),
        ],
      ),
    ],
  );
}
