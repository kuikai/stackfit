import '../exercise.dart';
import '../workout_plan.dart';
import 'plan_helpers.dart';

/// Run/walk progressions and speed sessions, all time based.
class RunningPlans {
  RunningPlans._();

  static const String category = 'Running';

  static final List<WorkoutPlan> all = [couchTo5k, speedSessions];

  static Exercise _walk(int minutes) =>
      PlanExercises.block('Brisk Walk', minutes);

  /// A jog block followed by a walk recovery, both in seconds.
  static Exercise _jogThenWalk(
    int jogSeconds,
    int walkSeconds, {
    int rounds = 1,
  }) {
    return PlanExercises.timer(
      'Jog (then walk)',
      work: jogSeconds,
      rest: walkSeconds,
      rounds: rounds,
    );
  }

  static Exercise _jog(int minutes) => PlanExercises.block('Jog', minutes);

  static PlanDay _runDay(String name, List<Exercise> mainSet) {
    return PlanDay(name: name, exercises: [_walk(5), ...mainSet, _walk(5)]);
  }

  // Source: nhs.uk Couch to 5K plan, c25k.com/c25k_plan
  static final WorkoutPlan couchTo5k = WorkoutPlan(
    id: 'running_couch_to_5k',
    name: 'Couch to 5K',
    category: category,
    level: 'Beginner',
    description:
        'Nine weeks, three runs a week. Each run starts and ends with a '
        'five-minute walk. Repeat a week if it felt too hard.',
    equipment: 'Running shoes',
    days: [
      _runDay('Week 1', [_jogThenWalk(60, 90, rounds: 8)]),
      _runDay('Week 2', [_jogThenWalk(90, 120, rounds: 6)]),
      _runDay('Week 3', [
        _jogThenWalk(90, 90),
        _jogThenWalk(180, 180),
        _jogThenWalk(90, 90),
        _jog(3),
      ]),
      _runDay('Week 4', [
        _jogThenWalk(180, 90),
        _jogThenWalk(300, 150),
        _jogThenWalk(180, 90),
        _jog(5),
      ]),
      _runDay('Week 5 · Run 1', [
        _jogThenWalk(300, 180),
        _jogThenWalk(300, 180),
        _jog(5),
      ]),
      _runDay('Week 5 · Run 2', [_jogThenWalk(480, 300), _jog(8)]),
      _runDay('Week 5 · Run 3', [_jog(20)]),
      _runDay('Week 6 · Run 1', [
        _jogThenWalk(300, 180),
        _jogThenWalk(480, 180),
        _jog(5),
      ]),
      _runDay('Week 6 · Run 2', [_jogThenWalk(600, 180), _jog(10)]),
      _runDay('Week 6 · Run 3', [_jog(25)]),
      _runDay('Week 7', [_jog(25)]),
      _runDay('Week 8', [_jog(28)]),
      _runDay('Week 9', [_jog(30)]),
    ],
  );

  // Source: fartlek.com, therunningchannel.com, yonderlustramblings.com
  static final WorkoutPlan speedSessions = WorkoutPlan(
    id: 'running_speed_sessions',
    name: 'Speed Sessions',
    category: category,
    level: 'Intermediate',
    description:
        'Four quality runs for someone who can already run 30 minutes. Do '
        'one per week alongside easy running.',
    equipment: 'Running shoes, a hill for the hill day',
    days: [
      PlanDay(
        name: 'Fartlek',
        exercises: [
          PlanExercises.block('Easy Run', 10),
          PlanExercises.timer(
            'Fast Surge (then easy jog)',
            work: 60,
            rest: 120,
            rounds: 6,
          ),
          PlanExercises.block('Easy Run', 5),
        ],
      ),
      PlanDay(
        name: 'Intervals',
        exercises: [
          PlanExercises.block('Easy Run', 10),
          PlanExercises.timer(
            'Hard Interval (then jog)',
            work: 90,
            rest: 120,
            rounds: 6,
          ),
          PlanExercises.block('Easy Run', 5),
        ],
      ),
      PlanDay(
        name: 'Tempo',
        exercises: [
          PlanExercises.block('Easy Run', 10),
          PlanExercises.block('Tempo Run', 20),
          PlanExercises.block('Easy Run', 10),
        ],
      ),
      PlanDay(
        name: 'Hills',
        exercises: [
          PlanExercises.block('Easy Run', 10),
          PlanExercises.timer(
            'Hill Sprint (then jog down)',
            work: 45,
            rest: 90,
            rounds: 6,
          ),
          PlanExercises.block('Easy Run', 5),
        ],
      ),
    ],
  );
}
