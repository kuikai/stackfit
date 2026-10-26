import '../workout_plan.dart';
import 'plan_helpers.dart';

/// Bodyweight, HIIT and single-kettlebell plans for home.
class HomePlans {
  HomePlans._();

  static const String category = 'Home';

  static final List<WorkoutPlan> all = [
    calisthenicsFoundations,
    bodyweightHiit,
    tabata,
    tenMinuteCore,
    kettlebellCircuit,
  ];

  // Source: theworkoutmag.com/programs/beginner-calisthenics-full-body-3-day-routine
  static final WorkoutPlan calisthenicsFoundations = WorkoutPlan(
    id: 'home_calisthenics_foundations',
    name: 'Calisthenics Foundations',
    category: category,
    level: 'Beginner',
    description:
        'Three sessions a week, alternating A and B. Move to a harder '
        'variation once you hit the top of the rep range with clean form.',
    equipment: 'Pull-up bar or rings, a bench or sturdy table',
    days: [
      PlanDay(
        name: 'Workout A',
        exercises: [
          PlanExercises.sets('Incline Push-ups', sets: 3, reps: 10),
          PlanExercises.sets('Inverted Rows', sets: 3, reps: 10),
          PlanExercises.sets('Bodyweight Squat', sets: 3, reps: 15, rest: 60),
          PlanExercises.timer('Dead Hang', work: 30, rest: 60, rounds: 3),
          PlanExercises.timer(
            'Hollow Body Hold',
            work: 20,
            rest: 60,
            rounds: 3,
          ),
          PlanExercises.sets('Glute Bridge', sets: 3, reps: 15, rest: 60),
        ],
      ),
      PlanDay(
        name: 'Workout B',
        exercises: [
          PlanExercises.sets('Negative Pull-ups', sets: 3, reps: 4, rest: 120),
          PlanExercises.sets('Pike Push-ups', sets: 3, reps: 6),
          PlanExercises.sets(
            'Single-leg Glute Bridge',
            sets: 3,
            reps: 8,
            rest: 60,
          ),
          PlanExercises.sets('Reverse Lunge', sets: 3, reps: 8, rest: 60),
          PlanExercises.timer('Plank', work: 30, rest: 60, rounds: 3),
          PlanExercises.sets('Scapular Shrugs', sets: 3, reps: 8, rest: 60),
        ],
      ),
    ],
  );

  // Source: honestbodyfitness.com/hiit-workout-at-home
  static final WorkoutPlan bodyweightHiit = WorkoutPlan(
    id: 'home_bodyweight_hiit',
    name: '20-min Bodyweight HIIT',
    category: category,
    level: 'Beginner',
    description:
        'Five moves, 40 seconds on and 20 off, four rounds with a minute '
        'between rounds. Use the easy version of any move when form slips.',
    equipment: 'None',
    days: [
      PlanDay(
        name: 'HIIT circuit',
        exercises: PlanExercises.circuit(
          const [
            'Bodyweight Squat',
            'Mountain Climbers',
            'Push-ups',
            'Reverse Lunge',
            'High Knees',
          ],
          work: 40,
          rest: 20,
          rounds: 4,
          roundRest: 60,
        ),
      ),
    ],
  );

  // Source: evofitness.at (Tabata protocol), crossrope.com
  static final WorkoutPlan tabata = WorkoutPlan(
    id: 'home_tabata',
    name: 'Tabata',
    category: category,
    level: 'Intermediate',
    description:
        'Two Tabata blocks: 20 seconds all-out, 10 seconds rest, eight '
        'rounds each, with a minute between blocks.',
    equipment: 'None',
    days: [
      PlanDay(
        name: 'Two blocks',
        exercises: [
          PlanExercises.timer('Burpees', work: 20, rest: 10, rounds: 8),
          PlanExercises.timer('Recover', work: 60),
          PlanExercises.timer('Jumping Jacks', work: 20, rest: 10, rounds: 8),
        ],
      ),
    ],
  );

  // Source: selffitwell.com 10-minute ab workout for beginners
  static final WorkoutPlan tenMinuteCore = WorkoutPlan(
    id: 'home_ten_minute_core',
    name: '10-min Core',
    category: category,
    level: 'Beginner',
    description:
        'Seven core moves, 40 seconds on and 20 off. Keep the lower back '
        'gently pressed into the floor on the lying moves.',
    equipment: 'Mat',
    days: [
      PlanDay(
        name: 'Core circuit',
        exercises: [
          PlanExercises.timer('Dead Bug', work: 40, rest: 20),
          PlanExercises.timer('Plank', work: 40, rest: 20),
          PlanExercises.timer('Bicycle Crunch', work: 40, rest: 20),
          PlanExercises.timer('Reverse Crunch', work: 40, rest: 20),
          PlanExercises.timer('Leg Lowers', work: 40, rest: 20),
          PlanExercises.timer('Side Plank (left)', work: 20, rest: 10),
          PlanExercises.timer('Side Plank (right)', work: 40),
        ],
      ),
    ],
  );

  // Source: bellsofsteel.com full-body kettlebell workout
  static final WorkoutPlan kettlebellCircuit = WorkoutPlan(
    id: 'home_kettlebell_circuit',
    name: '20-min Kettlebell',
    category: category,
    level: 'Beginner',
    description:
        'Four moves with one bell, 30 seconds on and 30 off, three rounds '
        'with a minute between rounds. One or two rounds is a fine start.',
    equipment: 'One kettlebell',
    days: [
      PlanDay(
        name: 'Kettlebell circuit',
        exercises: PlanExercises.circuit(
          const [
            'Kettlebell Swing',
            'Gorilla Row',
            'Goblet Squat',
            'Kettlebell Shoulder Press',
          ],
          work: 30,
          rest: 30,
          rounds: 3,
          roundRest: 60,
        ),
      ),
    ],
  );
}
