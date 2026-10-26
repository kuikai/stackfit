import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackfit/models/models.dart';
import 'package:stackfit/providers/in_progress_provider.dart';
import 'package:stackfit/services/storage_service.dart';
import 'package:stackfit/services/workout_session_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a saved run round-trips and keeps closed time off the clock', () {
    final now = DateTime.utc(2026, 10, 26, 12);
    final run = _run(elapsedSeconds: 40);

    final restored = InProgressWorkout.fromJson(run.toJson());

    expect(restored.workout.name, 'Push');
    expect(restored.origin, InProgressWorkout.planOrigin('p1', 'Push'));
    expect(restored.phase, 'rest');
    expect(restored.remainingSeconds, 20);
    expect(restored.setLogs.single.reps, 8);
    expect(restored.setLogs.single.weightKg, 60);
    expect(restored.draftEdited, isTrue);
    expect(restored.draftReps, 6);
    expect(restored.draftWeightKg, 62.5);
    expect(restored.afterRest, 'set');
    expect(restored.elapsedSeconds, 40);
    expect(
      restored.resumedStartedAt(now),
      now.subtract(const Duration(seconds: 40)),
    );
  });

  test('nothing is kept at the very start', () {
    final fresh = _run(
      elapsedSeconds: 0,
      phase: 'setReady',
      remainingSeconds: 0,
      setLogs: const [],
      draftEdited: false,
      afterRest: null,
    );

    expect(fresh.hasProgress, isFalse);
    expect(
      _run(
        elapsedSeconds: 1,
        phase: 'work',
        setLogs: const [],
        draftEdited: false,
        afterRest: null,
      ).hasProgress,
      isTrue,
    );
    expect(fresh.copyWithLog().hasProgress, isTrue);
    expect(
      _run(elapsedSeconds: 0, phase: 'setReady', draftEdited: true).hasProgress,
      isTrue,
    );
  });

  test('a rename still matches and a set change does not', () {
    final run = _run();
    final renamed = run.workout.copyWith(name: 'Push day');
    expect(run.matchesLayout(renamed), isTrue);

    final bench = run.workout.exercises.first;
    final changed = run.workout.copyWith(
      blocks: [ExerciseBlock(bench.copyWith(sets: 5))],
    );
    expect(run.matchesLayout(changed), isFalse);
  });

  test('continuing a rest goes to the next set, not the next exercise', () {
    final workout = _bench();
    final progress = _run(workout: workout);
    final controller = WorkoutSessionController(
      workout: workout,
      onWorkFinished: () {},
      onRestFinished: () {},
      onWorkoutFinished: () {},
      resumeState: stateFromProgress(
        progress,
        workout,
        DateTime.utc(2026, 10, 26, 12),
      ),
      resumeLogs: progress.setLogs,
      resumeAfterRest: progress.afterRest,
    );
    addTearDown(controller.disposeController);

    expect(controller.state.blockIndex, 0);
    expect(controller.state.setIndex, 0);
    expect(controller.state.phase, SessionPhase.rest);
    expect(controller.setLogs.single.reps, 8);

    controller.skipRest();

    expect(controller.state.phase, SessionPhase.setReady);
    expect(controller.state.setIndex, 1);
    expect(controller.state.currentExercise?.name, 'Bench');
  });

  test('the phone remembers a run and drops one bad record', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final notifier = InProgressNotifier(storage);
    final first = _run();
    final second = _run(
      workout: _bench(id: 'w2', exerciseId: 'e2'),
      origin: InProgressWorkout.planOrigin('p1', 'Pull'),
    );

    await notifier.save(first);
    await notifier.save(second);

    final loaded = InProgressNotifier(StorageService(prefs));
    expect(loaded.forWorkout('w1')?.elapsedSeconds, 40);
    expect(loaded.forOrigin(first.origin!)?.workout.name, 'Push');

    await loaded.discard('w1');
    expect(InProgressNotifier(StorageService(prefs)).state, hasLength(1));
  });

  test('the same plan day keeps one saved run', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifier = InProgressNotifier(StorageService(prefs));
    final origin = InProgressWorkout.planOrigin('p1', 'Push');
    await notifier.save(_run(origin: origin));
    await notifier.save(
      _run(
        workout: _bench(id: 'w9', exerciseId: 'e9'),
        origin: origin,
        elapsedSeconds: 15,
      ),
    );

    expect(notifier.state, hasLength(1));
    expect(notifier.forOrigin(origin)?.workout.id, 'w9');
    expect(notifier.forOrigin(origin)?.elapsedSeconds, 15);
  });

  test('unreadable progress JSON starts empty and skips a bad row', () async {
    SharedPreferences.setMockInitialValues({
      'stackfit_in_progress': 'not-json',
    });
    final broken = await SharedPreferences.getInstance();
    expect(StorageService(broken).loadInProgress(), isEmpty);

    SharedPreferences.setMockInitialValues({
      'stackfit_in_progress': jsonEncode([
        {'workout': 'bad'},
        _run().toJson(),
      ]),
    });
    final mixed = await SharedPreferences.getInstance();
    expect(StorageService(mixed).loadInProgress(), hasLength(1));
  });
}

Workout _bench({String id = 'w1', String exerciseId = 'e1'}) {
  return Workout(
    id: id,
    name: 'Push',
    createdAt: DateTime.utc(2026, 10, 26),
    updatedAt: DateTime.utc(2026, 10, 26),
    blocks: [
      ExerciseBlock(
        Exercise.sets(
          id: exerciseId,
          name: 'Bench',
          sets: 3,
          reps: 8,
          restSeconds: 60,
        ),
      ),
    ],
  );
}

InProgressWorkout _run({
  Workout? workout,
  String? origin,
  int elapsedSeconds = 40,
  String phase = 'rest',
  int remainingSeconds = 20,
  List<SetLog>? setLogs,
  bool draftEdited = true,
  String? afterRest = 'set',
}) {
  final session = workout ?? _bench();
  return InProgressWorkout(
    workout: session,
    origin: origin ?? InProgressWorkout.planOrigin('p1', 'Push'),
    blockIndex: 0,
    roundIndex: 0,
    exerciseIndex: 0,
    setIndex: 0,
    phase: phase,
    remainingSeconds: remainingSeconds,
    isPaused: false,
    elapsedSeconds: elapsedSeconds,
    setLogs:
        setLogs ??
        [
          SetLog(
            exerciseId: session.exercises.first.id,
            exerciseName: 'Bench',
            setNumber: 1,
            reps: 8,
            weightKg: 60,
          ),
        ],
    draftEdited: draftEdited,
    draftReps: 6,
    draftWeightKg: 62.5,
    afterRest: afterRest,
    savedAt: DateTime.utc(2026, 10, 26, 11),
  );
}

extension on InProgressWorkout {
  InProgressWorkout copyWithLog() {
    return InProgressWorkout(
      workout: workout,
      origin: origin,
      blockIndex: blockIndex,
      roundIndex: roundIndex,
      exerciseIndex: exerciseIndex,
      setIndex: setIndex,
      phase: phase,
      remainingSeconds: remainingSeconds,
      isPaused: isPaused,
      elapsedSeconds: elapsedSeconds,
      setLogs: const [
        SetLog(exerciseId: 'e1', exerciseName: 'Bench', setNumber: 1, reps: 8),
      ],
      savedAt: savedAt,
    );
  }
}
