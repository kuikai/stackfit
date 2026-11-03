import 'package:flutter_test/flutter_test.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/services/workout_session_controller.dart';

void main() {
  testWidgets('work and rest each beep on 3, 2, 1, and 0', (tester) async {
    final clock = _Clock(DateTime.utc(2026, 10, 29, 12));
    final heard = <int>[];
    final controller = WorkoutSessionController(
      workout: _timer(work: 5, rest: 4),
      onWorkFinished: () {},
      onRestFinished: () {},
      onWorkoutFinished: () {},
      onCountdown: heard.add,
      clock: clock.call,
    );
    controller.startWork();
    expect(heard, isEmpty);

    await _step(tester, clock, const Duration(seconds: 1));
    expect(controller.state.remainingSeconds, 4);
    expect(heard, isEmpty);

    await _step(tester, clock, const Duration(seconds: 1));
    await _step(tester, clock, const Duration(seconds: 1));
    await _step(tester, clock, const Duration(seconds: 1));
    expect(heard, [3, 2, 1]);

    await _step(tester, clock, const Duration(seconds: 1));
    expect(controller.state.phase, SessionPhase.rest);
    expect(controller.state.remainingSeconds, 4);
    expect(heard, [3, 2, 1, 0]);

    await _step(tester, clock, const Duration(seconds: 1));
    expect(controller.state.remainingSeconds, 3);
    expect(heard, [3, 2, 1, 0, 3]);

    await _step(tester, clock, const Duration(seconds: 1));
    await _step(tester, clock, const Duration(seconds: 1));
    expect(heard, [3, 2, 1, 0, 3, 2, 1]);

    await _step(tester, clock, const Duration(seconds: 1));
    expect(controller.state.phase, SessionPhase.work);
    expect(heard, [3, 2, 1, 0, 3, 2, 1, 0]);
    controller.disposeController();
  });

  testWidgets('skipping rest does not beep zero', (tester) async {
    final clock = _Clock(DateTime.utc(2026, 10, 29, 12));
    final heard = <int>[];
    final controller = WorkoutSessionController(
      workout: _timer(work: 1, rest: 10),
      onWorkFinished: () {},
      onRestFinished: () {},
      onWorkoutFinished: () {},
      onCountdown: heard.add,
      clock: clock.call,
    );
    controller.startWork();
    expect(heard, [1]);

    await _step(tester, clock, const Duration(seconds: 1));
    expect(controller.state.phase, SessionPhase.rest);
    expect(heard, [1, 0]);

    controller.skipRest();
    expect(heard.where((second) => second == 0), [0]);
    expect(controller.state.phase, isNot(SessionPhase.rest));
    controller.disposeController();
  });

  test('a 3 second work beeps as soon as it starts', () {
    final heard = <int>[];
    final controller = WorkoutSessionController(
      workout: _timer(work: 3, rest: 10),
      onWorkFinished: () {},
      onRestFinished: () {},
      onWorkoutFinished: () {},
      onCountdown: heard.add,
      clock: DateTime.now,
    );
    addTearDown(controller.disposeController);

    expect(controller.state.phase, SessionPhase.workReady);
    controller.startWork();
    expect(heard, [3]);
  });

  test('a rest that jumps to 2 seconds beeps once', () {
    final clock = _Clock(DateTime.utc(2026, 10, 29, 12));
    final heard = <int>[];
    final controller = WorkoutSessionController(
      workout: _sets(),
      onWorkFinished: () {},
      onRestFinished: () {},
      onWorkoutFinished: () {},
      onCountdown: heard.add,
      clock: clock.call,
    );
    addTearDown(controller.disposeController);

    controller.completeSet(repsDone: 8);
    expect(controller.state.remainingSeconds, 60);
    expect(heard, isEmpty);

    controller.freezeClock();
    clock.advance(const Duration(seconds: 58));
    controller.thawClock();

    expect(controller.state.remainingSeconds, 2);
    expect(heard, [2]);
  });
}

Future<void> _step(WidgetTester tester, _Clock clock, Duration by) async {
  clock.advance(by);
  await tester.pump(by);
}

class _Clock {
  _Clock(this._now);

  DateTime _now;

  DateTime call() => _now;

  void advance(Duration by) {
    _now = _now.add(by);
  }
}

Workout _timer({required int work, required int rest}) {
  final now = DateTime.utc(2026, 10, 29);
  return Workout(
    id: 'timed',
    name: 'Core',
    createdAt: now,
    updatedAt: now,
    blocks: [
      ExerciseBlock(
        Exercise.timer(
          id: 'plank',
          name: 'Plank',
          workSeconds: work,
          restSeconds: rest,
          sets: 2,
        ),
      ),
    ],
  );
}

Workout _sets() {
  final now = DateTime.utc(2026, 10, 29);
  return Workout(
    id: 'sets',
    name: 'Bench',
    createdAt: now,
    updatedAt: now,
    blocks: [
      ExerciseBlock(
        Exercise.sets(
          id: 'bench',
          name: 'Bench',
          sets: 2,
          reps: 8,
          restSeconds: 60,
        ),
      ),
    ],
  );
}
