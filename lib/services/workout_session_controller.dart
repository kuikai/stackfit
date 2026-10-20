import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';

enum SessionPhase {
  /// Timer exercise: work countdown.
  work,

  /// Rest countdown (after work or after a set).
  rest,

  /// Set exercise: waiting for user to tap Done.
  setReady,

  /// Workout finished.
  complete,
}

class WorkoutSessionState {
  const WorkoutSessionState({
    required this.workout,
    required this.exerciseIndex,
    required this.setIndex,
    required this.phase,
    required this.remainingSeconds,
    required this.isPaused,
    required this.startedAt,
  });

  final Workout workout;
  final int exerciseIndex;
  final int setIndex;
  final SessionPhase phase;
  final int remainingSeconds;
  final bool isPaused;
  final DateTime startedAt;

  Exercise? get currentExercise {
    if (exerciseIndex < 0 || exerciseIndex >= workout.exercises.length) {
      return null;
    }
    return workout.exercises[exerciseIndex];
  }

  int get exerciseNumber => exerciseIndex + 1;
  int get exerciseCount => workout.exercises.length;

  int get setNumber => setIndex + 1;
  int get totalSets => currentExercise?.sets ?? 0;

  bool get isComplete => phase == SessionPhase.complete;

  int get elapsedSeconds {
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  WorkoutSessionState copyWith({
    int? exerciseIndex,
    int? setIndex,
    SessionPhase? phase,
    int? remainingSeconds,
    bool? isPaused,
  }) {
    return WorkoutSessionState(
      workout: workout,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      setIndex: setIndex ?? this.setIndex,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isPaused: isPaused ?? this.isPaused,
      startedAt: startedAt,
    );
  }
}

/// Runs a workout: timer countdowns, set prompts, rest, skip, pause, stop.
class WorkoutSessionController extends ChangeNotifier {
  WorkoutSessionController({
    required Workout workout,
    required this.onWorkFinished,
    required this.onRestFinished,
    required this.onWorkoutFinished,
  }) : state = WorkoutSessionState(
          workout: workout,
          exerciseIndex: 0,
          setIndex: 0,
          phase: SessionPhase.work,
          remainingSeconds: 0,
          isPaused: false,
          startedAt: DateTime.now(),
        ) {
    if (workout.exercises.isEmpty) {
      state = state.copyWith(phase: SessionPhase.complete);
    } else {
      _enterExercise(0);
    }
  }

  final VoidCallback onWorkFinished;
  final VoidCallback onRestFinished;
  final VoidCallback onWorkoutFinished;

  WorkoutSessionState state;
  Timer? _ticker;

  /// True when current rest follows the last set of a sets exercise.
  bool _restAfterLastSet = false;

  final List<SetLog> _setLogs = [];

  /// Reps logged so far, in the order sets were completed.
  List<SetLog> get setLogs => List.unmodifiable(_setLogs);

  /// The set just completed, while its rest is running. Null otherwise.
  SetLog? get restingSetLog {
    if (state.phase != SessionPhase.rest || _setLogs.isEmpty) {
      return null;
    }
    if (state.currentExercise?.type != ExerciseType.sets) {
      return null;
    }
    return _setLogs.last;
  }

  /// Changes the reps recorded for the set that just finished.
  void updateLastSetReps(int reps) {
    if (_setLogs.isEmpty || reps < 0) {
      return;
    }
    _setLogs[_setLogs.length - 1] = _setLogs.last.copyWith(reps: reps);
    notifyListeners();
  }

  /// Changes reps and/or weight for any logged set of an exercise.
  void updateSetLog(
    String exerciseId,
    int setNumber, {
    int? reps,
    double? weightKg,
  }) {
    if ((reps != null && reps < 0) || (weightKg != null && weightKg < 0)) {
      return;
    }
    for (var i = 0; i < _setLogs.length; i++) {
      final log = _setLogs[i];
      if (log.exerciseId == exerciseId && log.setNumber == setNumber) {
        _setLogs[i] = log.copyWith(reps: reps, weightKg: weightKg);
        notifyListeners();
        return;
      }
    }
  }

  /// Logs for the exercise currently on screen, oldest first.
  List<SetLog> get currentExerciseLogs {
    final exercise = state.currentExercise;
    if (exercise == null) {
      return const [];
    }
    return _setLogs.where((log) => log.exerciseId == exercise.id).toList();
  }

  void disposeController() {
    _ticker?.cancel();
    _ticker = null;
  }

  void togglePause() {
    if (state.isComplete) {
      return;
    }
    if (state.phase == SessionPhase.setReady) {
      return;
    }
    state = state.copyWith(isPaused: !state.isPaused);
    if (state.isPaused) {
      _stopTicker();
    } else if (state.phase == SessionPhase.work ||
        state.phase == SessionPhase.rest) {
      _startTicker();
    }
    notifyListeners();
  }

  void skipRest() {
    if (state.phase != SessionPhase.rest || state.isComplete) {
      return;
    }
    _finishRest(playAlarm: false);
  }

  /// Restart the whole workout from the first exercise.
  void restart() {
    if (state.workout.exercises.isEmpty) {
      return;
    }
    _stopTicker();
    _restAfterLastSet = false;
    _setLogs.clear();
    state = WorkoutSessionState(
      workout: state.workout,
      exerciseIndex: 0,
      setIndex: 0,
      phase: SessionPhase.work,
      remainingSeconds: 0,
      isPaused: false,
      startedAt: DateTime.now(),
    );
    _enterExercise(0);
  }

  /// Skip current work interval, rest, or set.
  void skipCurrent() {
    if (state.isComplete) {
      return;
    }
    switch (state.phase) {
      case SessionPhase.work:
        _beginRestAfterWork();
        break;
      case SessionPhase.rest:
        _finishRest(playAlarm: false);
        break;
      case SessionPhase.setReady:
        completeSet();
        break;
      case SessionPhase.complete:
        break;
    }
  }

  /// Marks the current set done. [repsDone] defaults to the planned reps.
  void completeSet({int? repsDone, double? weightKg}) {
    if (state.phase != SessionPhase.setReady || state.isComplete) {
      return;
    }
    final exercise = state.currentExercise;
    if (exercise == null || exercise.type != ExerciseType.sets) {
      return;
    }

    _setLogs.add(
      SetLog(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        setNumber: state.setNumber,
        reps: repsDone ?? exercise.reps ?? 0,
        weightKg: weightKg,
      ),
    );

    final totalSets = exercise.sets ?? 1;
    final isLastSet = state.setIndex >= totalSets - 1;
    final restSeconds = exercise.restSeconds ?? 0;

    if (restSeconds > 0) {
      _restAfterLastSet = isLastSet;
      state = state.copyWith(
        phase: SessionPhase.rest,
        remainingSeconds: restSeconds,
        isPaused: false,
      );
      _startTicker();
      notifyListeners();
      return;
    }

    if (isLastSet) {
      _goToNextExercise();
    } else {
      state = state.copyWith(
        setIndex: state.setIndex + 1,
        phase: SessionPhase.setReady,
        remainingSeconds: 0,
        isPaused: false,
      );
      _stopTicker();
      notifyListeners();
    }
  }

  void _enterExercise(int index) {
    _restAfterLastSet = false;
    final exercise = state.workout.exercises[index];

    if (exercise.type == ExerciseType.timer) {
      final work = exercise.workSeconds ?? 0;
      final rest = exercise.restSeconds ?? 0;
      state = state.copyWith(
        exerciseIndex: index,
        setIndex: 0,
        phase: work > 0 ? SessionPhase.work : SessionPhase.rest,
        remainingSeconds: work > 0 ? work : rest,
        isPaused: false,
      );
      if (work > 0) {
        _startTicker();
        notifyListeners();
        return;
      }
      if (rest > 0) {
        _startTicker();
        notifyListeners();
        return;
      }
      _goToNextExercise();
      return;
    }

    state = state.copyWith(
      exerciseIndex: index,
      setIndex: 0,
      phase: SessionPhase.setReady,
      remainingSeconds: 0,
      isPaused: false,
    );
    _stopTicker();
    notifyListeners();
  }

  void _beginRestAfterWork() {
    onWorkFinished();
    final exercise = state.currentExercise;
    if (exercise == null) {
      _goToNextExercise();
      return;
    }

    final rest = exercise.restSeconds ?? 0;
    final totalRounds = exercise.sets ?? 1;
    final isLastRound = state.setIndex >= totalRounds - 1;

    // Timer: rest between rounds only (skip rest after the final round).
    if (exercise.type == ExerciseType.timer) {
      if (isLastRound) {
        _goToNextExercise();
        return;
      }
      if (rest > 0) {
        _restAfterLastSet = false;
        state = state.copyWith(
          phase: SessionPhase.rest,
          remainingSeconds: rest,
          isPaused: false,
        );
        _startTicker();
        notifyListeners();
        return;
      }
      _startNextTimerRound();
      return;
    }

    _restAfterLastSet = false;
    if (rest > 0) {
      state = state.copyWith(
        phase: SessionPhase.rest,
        remainingSeconds: rest,
        isPaused: false,
      );
      _startTicker();
      notifyListeners();
    } else {
      _goToNextExercise();
    }
  }

  void _finishRest({required bool playAlarm}) {
    if (playAlarm) {
      onRestFinished();
    }
    final exercise = state.currentExercise;

    if (exercise?.type == ExerciseType.timer) {
      _startNextTimerRound();
      return;
    }

    if (exercise?.type == ExerciseType.sets && !_restAfterLastSet) {
      state = state.copyWith(
        setIndex: state.setIndex + 1,
        phase: SessionPhase.setReady,
        remainingSeconds: 0,
        isPaused: false,
      );
      _stopTicker();
      notifyListeners();
      return;
    }
    _goToNextExercise();
  }

  void _startNextTimerRound() {
    final exercise = state.currentExercise;
    final work = exercise?.workSeconds ?? 0;
    final nextRound = state.setIndex + 1;
    final totalRounds = exercise?.sets ?? 1;

    if (nextRound >= totalRounds) {
      _goToNextExercise();
      return;
    }

    if (work <= 0) {
      _goToNextExercise();
      return;
    }

    state = state.copyWith(
      setIndex: nextRound,
      phase: SessionPhase.work,
      remainingSeconds: work,
      isPaused: false,
    );
    _startTicker();
    notifyListeners();
  }

  void _goToNextExercise() {
    final next = state.exerciseIndex + 1;
    if (next >= state.workout.exercises.length) {
      _completeWorkout();
      return;
    }
    _enterExercise(next);
  }

  void _completeWorkout() {
    _stopTicker();
    state = state.copyWith(
      phase: SessionPhase.complete,
      remainingSeconds: 0,
      isPaused: false,
    );
    notifyListeners();
    onWorkoutFinished();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _onTick() {
    if (state.isPaused || state.isComplete) {
      return;
    }
    if (state.phase != SessionPhase.work && state.phase != SessionPhase.rest) {
      return;
    }

    final next = state.remainingSeconds - 1;
    if (next > 0) {
      state = state.copyWith(remainingSeconds: next);
      notifyListeners();
      return;
    }

    state = state.copyWith(remainingSeconds: 0);
    notifyListeners();

    if (state.phase == SessionPhase.work) {
      _beginRestAfterWork();
    } else if (state.phase == SessionPhase.rest) {
      _finishRest(playAlarm: true);
    }
  }
}
