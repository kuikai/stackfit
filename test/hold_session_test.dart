import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/services/workout_session_controller.dart';

void main() {
  test('a hold starts at zero and Done stores 45 seconds', () {
    final clock = _Clock(DateTime.utc(2026, 11, 9, 12));
    final heard = <int>[];
    final controller = _controller(_plank(), clock, heard);
    addTearDown(controller.disposeController);

    expect(controller.state.phase, SessionPhase.hold);
    expect(controller.displayedSeconds, 0);

    clock.advance(const Duration(seconds: 45));
    controller.completeHold();

    expect(controller.setLogs, hasLength(1));
    expect(controller.setLogs.single.heldSeconds, 45);
    expect(controller.setLogs.single.reps, 0);
    expect(controller.setLogs.single.shortLabel, '0:45');
    expect(SetLog.formatHeld(65), '1:05');
    expect(controller.state.phase, SessionPhase.complete);
    expect(heard, isEmpty);
  });

  test('a second attempt is a second log', () {
    final clock = _Clock(DateTime.utc(2026, 11, 9, 12));
    final controller = _controller(_plank(attempts: 2), clock, []);
    addTearDown(controller.disposeController);

    clock.advance(const Duration(seconds: 45));
    controller.completeHold();
    expect(controller.state.phase, SessionPhase.hold);
    expect(controller.state.setIndex, 1);
    expect(controller.displayedSeconds, 0);

    clock.advance(const Duration(seconds: 12));
    controller.completeHold();

    expect(controller.setLogs.map((log) => log.heldSeconds), [45, 12]);
    expect(controller.setLogs.map((log) => log.setNumber), [1, 2]);
    expect(SetLog.summarize(controller.setLogs), '0:45 · 0:12');
    expect(controller.state.phase, SessionPhase.complete);
  });

  test('pause freezes a hold', () {
    final clock = _Clock(DateTime.utc(2026, 11, 9, 12));
    final controller = _controller(_plank(), clock, []);
    addTearDown(controller.disposeController);

    clock.advance(const Duration(seconds: 10));
    controller.togglePause();
    expect(controller.state.isPaused, isTrue);
    expect(controller.displayedSeconds, 10);

    clock.advance(const Duration(seconds: 25));
    expect(controller.displayedSeconds, 10);

    controller.togglePause();
    clock.advance(const Duration(seconds: 5));
    controller.completeHold();
    expect(controller.setLogs.single.heldSeconds, 15);
  });

  test('locking the phone keeps the hold counting', () {
    final start = DateTime.utc(2026, 11, 9, 12);
    final savedAt = start.add(const Duration(seconds: 10));
    final workout = _plank();
    final progress = InProgressWorkout(
      workout: workout,
      blockIndex: 0,
      roundIndex: 0,
      exerciseIndex: 0,
      setIndex: 0,
      phase: 'hold',
      remainingSeconds: 10,
      isPaused: false,
      elapsedSeconds: 10,
      holdStartedAt: start,
      savedAt: savedAt,
    );
    final later = start.add(const Duration(seconds: 30));

    expect(progress.holdSecondsAt(later), 30);
    expect(progress.canResume, isTrue);

    final clock = _Clock(later);
    final controller = WorkoutSessionController(
      workout: workout,
      onWorkFinished: () {},
      onRestFinished: () {},
      onWorkoutFinished: () {},
      resumeState: stateFromProgress(progress, workout, later),
      clock: clock.call,
    );
    addTearDown(controller.disposeController);

    expect(controller.state.phase, SessionPhase.hold);
    expect(controller.displayedSeconds, 30);
    clock.advance(const Duration(seconds: 4));
    controller.completeHold();
    expect(controller.setLogs.single.heldSeconds, 34);
  });

  test('leaving a hold does not add time spent away', () {
    final savedAt = DateTime.utc(2026, 11, 9, 12, 0, 45);
    final workout = _plank();
    final progress = InProgressWorkout(
      workout: workout,
      blockIndex: 0,
      roundIndex: 0,
      exerciseIndex: 0,
      setIndex: 0,
      phase: 'hold',
      remainingSeconds: 45,
      isPaused: false,
      elapsedSeconds: 45,
      savedAt: savedAt,
    );
    final later = savedAt.add(const Duration(minutes: 10));

    expect(progress.holdSecondsAt(later), 45);
    expect(
      progress.resumedStartedAt(later),
      later.subtract(const Duration(seconds: 45)),
    );

    final clock = _Clock(later);
    final controller = WorkoutSessionController(
      workout: workout,
      onWorkFinished: () {},
      onRestFinished: () {},
      onWorkoutFinished: () {},
      resumeState: stateFromProgress(progress, workout, later),
      clock: clock.call,
    );
    addTearDown(controller.disposeController);

    expect(controller.displayedSeconds, 45);
    clock.advance(const Duration(seconds: 3));
    controller.completeHold();
    expect(controller.setLogs.single.heldSeconds, 48);
  });
}

Workout _plank({int attempts = 1}) {
  return Workout(
    id: 'w1',
    name: 'Plank',
    exercises: [
      Exercise.hold(id: 'plank', name: 'Plank', sets: attempts, restSeconds: 0),
    ],
    createdAt: DateTime.utc(2026, 11, 9),
    updatedAt: DateTime.utc(2026, 11, 9),
  );
}

WorkoutSessionController _controller(
  Workout workout,
  _Clock clock,
  List<int> heard,
) {
  return WorkoutSessionController(
    workout: workout,
    onWorkFinished: () {},
    onRestFinished: () {},
    onWorkoutFinished: () {},
    onCountdown: heard.add,
    clock: clock.call,
  );
}

class _Clock {
  _Clock(this.now);

  DateTime now;

  DateTime call() => now;

  void advance(Duration by) {
    now = now.add(by);
  }
}
