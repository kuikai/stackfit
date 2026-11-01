import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/services/station_exit.dart';
import 'package:stackfit/services/workout_session_controller.dart';

void main() {
  test('old workouts load as single exercises and circuits round-trip', () {
    final old = Workout.fromJson({
      'id': 'w1',
      'name': 'Push',
      'createdAt': '2026-10-01T10:00:00.000Z',
      'updatedAt': '2026-10-01T10:00:00.000Z',
      'exercises': [
        {
          'id': 'e1',
          'name': 'Bench',
          'type': 'sets',
          'sets': 3,
          'reps': 8,
          'restSeconds': 60,
        },
      ],
    });
    expect(old.blocks.single, isA<ExerciseBlock>());
    expect(old.exercises.single.name, 'Bench');

    final circuit = Workout(
      id: 'w2',
      name: 'Circuit day',
      createdAt: DateTime.utc(2026, 10, 2),
      updatedAt: DateTime.utc(2026, 10, 2),
      blocks: [
        ExerciseBlock(
          Exercise.timer(
            id: 'warm',
            name: 'Jumping jacks',
            workSeconds: 30,
            restSeconds: 0,
          ),
        ),
        CircuitBlock(
          Circuit(
            id: 'c1',
            rounds: 3,
            restBetweenRoundsSeconds: 60,
            exercises: [
              Exercise.timer(
                id: 'push',
                name: 'Push-ups',
                workSeconds: 40,
                restSeconds: 15,
              ),
              Exercise.sets(
                id: 'squat',
                name: 'Squats',
                sets: 1,
                reps: 10,
                restSeconds: 15,
              ),
            ],
          ),
        ),
      ],
    );

    final restored = Workout.fromJson(circuit.toJson());
    expect(restored.exercises, hasLength(3));
    expect(restored.blocks[1], isA<CircuitBlock>());
    final box = (restored.blocks[1] as CircuitBlock).circuit;
    expect(box.rounds, 3);
    expect(box.restBetweenRoundsSeconds, 60);
    expect(box.exercises.map((exercise) => exercise.name), [
      'Push-ups',
      'Squats',
    ]);
    expect(restored.estimatedDurationSeconds, greaterThan(60));
  });

  test('station exit rests between stations and between rounds', () {
    final workout = _circuitWorkout();

    final between = planStationExit(
      workout: workout,
      blockIndex: 1,
      roundIndex: 0,
      exerciseIndex: 0,
      restAfterLastSet: false,
    );
    expect(between.destination, StationDestination.station);
    expect(between.restSeconds, 10);

    final nextRound = planStationExit(
      workout: workout,
      blockIndex: 1,
      roundIndex: 0,
      exerciseIndex: 1,
      restAfterLastSet: false,
    );
    expect(nextRound.destination, StationDestination.round);
    expect(nextRound.restSeconds, 20);

    final leave = planStationExit(
      workout: workout,
      blockIndex: 1,
      roundIndex: 1,
      exerciseIndex: 1,
      restAfterLastSet: true,
    );
    expect(leave.destination, StationDestination.block);
    expect(leave.restSeconds, 15);

    final timerLeaves = planStationExit(
      workout: workout,
      blockIndex: 1,
      roundIndex: 1,
      exerciseIndex: 1,
      restAfterLastSet: false,
    );
    expect(timerLeaves.destination, StationDestination.block);
    expect(timerLeaves.restSeconds, 0);

    final plain = planStationExit(
      workout: workout,
      blockIndex: 0,
      roundIndex: 0,
      exerciseIndex: 0,
      restAfterLastSet: false,
    );
    expect(plain.destination, StationDestination.block);
    expect(plain.restSeconds, 0);
  });

  test('a circuit repeats, then the workout continues', () {
    final controller = WorkoutSessionController(
      workout: _circuitWorkout(),
      onWorkFinished: () {},
      onRestFinished: () {},
      onWorkoutFinished: () {},
    );
    addTearDown(controller.disposeController);

    expect(controller.state.currentExercise?.name, 'Jumping jacks');
    controller.skipCurrent();
    expect(controller.state.currentExercise?.name, 'Push-ups');
    expect(controller.state.progressLabel, 'Round 1 of 2 · Station 1 of 2');

    controller.skipCurrent();
    expect(controller.state.phase, SessionPhase.rest);
    controller.skipRest();
    expect(controller.state.currentExercise?.name, 'Squats');

    controller.completeSet(repsDone: 10);
    expect(controller.state.phase, SessionPhase.rest);
    expect(controller.state.remainingSeconds, 20);
    controller.skipRest();
    expect(controller.state.progressLabel, 'Round 2 of 2 · Station 1 of 2');

    controller.skipCurrent();
    controller.skipRest();
    controller.completeSet(repsDone: 8);
    controller.skipRest();
    expect(controller.state.currentExercise?.name, 'Plank');
    controller.completeSet(repsDone: 1);
    expect(controller.state.isComplete, isTrue);

    expect(controller.setLogs.map((log) => log.round), [1, 2, 1]);
    controller.updateSetLog('squat', 1, round: 1, reps: 12);
    expect(controller.setLogs.first.reps, 12);
    expect(controller.setLogs[1].reps, 8);
  });

  test('a circuit names the next station', () {
    final workout = _circuitWorkout();
    WorkoutSessionState at({
      required int block,
      required int round,
      required int station,
    }) {
      return WorkoutSessionState(
        workout: workout,
        blockIndex: block,
        roundIndex: round,
        exerciseIndex: station,
        setIndex: 0,
        phase: SessionPhase.work,
        remainingSeconds: 0,
        isPaused: false,
        startedAt: DateTime.utc(2026, 10, 23),
      );
    }

    expect(at(block: 0, round: 0, station: 0).nextExercise, isNull);
    expect(at(block: 1, round: 0, station: 0).nextExercise?.name, 'Squats');
    expect(at(block: 1, round: 0, station: 1).nextExercise?.name, 'Push-ups');
    expect(at(block: 1, round: 1, station: 1).nextExercise?.name, 'Plank');
    expect(at(block: 2, round: 0, station: 0).nextExercise, isNull);
  });

  test('rest keeps counting while the app is away', () {
    final clock = _Clock(DateTime.utc(2026, 10, 29, 12));
    var alarms = 0;
    final controller = _controller(
      workout: _setsWorkout(),
      clock: clock,
      onRestFinished: () => alarms++,
    );

    controller.completeSet(repsDone: 8);
    expect(controller.state.phase, SessionPhase.rest);
    expect(controller.state.remainingSeconds, 60);

    controller.freezeClock();
    clock.advance(const Duration(seconds: 10));
    controller.freezeClock();
    clock.advance(const Duration(seconds: 15));
    controller.thawClock();

    expect(controller.state.phase, SessionPhase.rest);
    expect(controller.state.remainingSeconds, 35);
    expect(controller.elapsedSeconds, 25);
    expect(alarms, 0);

    controller.freezeClock();
    clock.advance(const Duration(seconds: 40));
    controller.thawClock();

    expect(controller.state.phase, SessionPhase.setReady);
    expect(controller.state.setIndex, 1);
    expect(alarms, 1);
    expect(controller.elapsedSeconds, 65);
  });

  test('a work interval stays put while the app is away', () {
    final clock = _Clock(DateTime.utc(2026, 10, 29, 12));
    final controller = _controller(workout: _timerWorkout(), clock: clock);

    expect(controller.state.phase, SessionPhase.work);
    expect(controller.state.remainingSeconds, 30);

    controller.freezeClock();
    clock.advance(const Duration(seconds: 20));
    controller.thawClock();

    expect(controller.state.phase, SessionPhase.work);
    expect(controller.state.remainingSeconds, 30);
    expect(controller.elapsedSeconds, 0);
  });

  test('a paused rest stays put while the app is away', () {
    final clock = _Clock(DateTime.utc(2026, 10, 29, 12));
    final controller = _controller(workout: _setsWorkout(), clock: clock);

    controller.completeSet(repsDone: 8);
    controller.togglePause();
    final left = controller.state.remainingSeconds;

    controller.freezeClock();
    clock.advance(const Duration(seconds: 30));
    controller.thawClock();

    expect(controller.state.isPaused, isTrue);
    expect(controller.state.phase, SessionPhase.rest);
    expect(controller.state.remainingSeconds, left);
    expect(controller.elapsedSeconds, 0);
  });
}

class _Clock {
  _Clock(this._now);

  DateTime _now;

  DateTime call() => _now;

  void advance(Duration by) {
    _now = _now.add(by);
  }
}

WorkoutSessionController _controller({
  required Workout workout,
  required _Clock clock,
  void Function()? onRestFinished,
}) {
  final controller = WorkoutSessionController(
    workout: workout,
    onWorkFinished: () {},
    onRestFinished: onRestFinished ?? () {},
    onWorkoutFinished: () {},
    clock: clock.call,
  );
  addTearDown(controller.disposeController);
  return controller;
}

Workout _setsWorkout() {
  return Workout(
    id: 'sets',
    name: 'Bench',
    createdAt: DateTime.utc(2026, 10, 29),
    updatedAt: DateTime.utc(2026, 10, 29),
    blocks: [
      ExerciseBlock(
        Exercise.sets(
          id: 'bench',
          name: 'Bench',
          sets: 3,
          reps: 8,
          restSeconds: 60,
        ),
      ),
    ],
  );
}

Workout _timerWorkout() {
  return Workout(
    id: 'timer',
    name: 'Plank',
    createdAt: DateTime.utc(2026, 10, 29),
    updatedAt: DateTime.utc(2026, 10, 29),
    blocks: [
      ExerciseBlock(
        Exercise.timer(
          id: 'plank',
          name: 'Plank',
          workSeconds: 30,
          restSeconds: 10,
        ),
      ),
    ],
  );
}

Workout _circuitWorkout() {
  return Workout(
    id: 'w',
    name: 'Mixed',
    createdAt: DateTime.utc(2026, 10, 23),
    updatedAt: DateTime.utc(2026, 10, 23),
    blocks: [
      ExerciseBlock(
        Exercise.timer(
          id: 'warm',
          name: 'Jumping jacks',
          workSeconds: 20,
          restSeconds: 0,
          sets: 1,
        ),
      ),
      CircuitBlock(
        Circuit(
          id: 'c',
          rounds: 2,
          restBetweenRoundsSeconds: 20,
          exercises: [
            Exercise.timer(
              id: 'push',
              name: 'Push-ups',
              workSeconds: 30,
              restSeconds: 10,
              sets: 1,
            ),
            Exercise.sets(
              id: 'squat',
              name: 'Squats',
              sets: 1,
              reps: 10,
              restSeconds: 15,
            ),
          ],
        ),
      ),
      ExerciseBlock(
        Exercise.sets(
          id: 'plank',
          name: 'Plank',
          sets: 1,
          reps: 1,
          restSeconds: 0,
        ),
      ),
    ],
  );
}
