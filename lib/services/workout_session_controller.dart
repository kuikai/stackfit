import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'session_set_log.dart';
import 'station_exit.dart';
import 'workout_session_state.dart';

export 'workout_session_state.dart';

part 'workout_session_phases.dart';

/// Runs a workout: timer countdowns, set prompts, rest, skip, pause, stop.
class WorkoutSessionController extends ChangeNotifier
    with WorkoutSessionPhases {
  WorkoutSessionController({
    required Workout workout,
    required this.onWorkFinished,
    required this.onRestFinished,
    required this.onWorkoutFinished,
    WorkoutSessionState? resumeState,
    List<SetLog>? resumeLogs,
    String? resumeAfterRest,
  }) : state =
           resumeState ??
           WorkoutSessionState(
             workout: workout,
             blockIndex: 0,
             roundIndex: 0,
             exerciseIndex: 0,
             setIndex: 0,
             phase: SessionPhase.work,
             remainingSeconds: 0,
             isPaused: false,
             startedAt: DateTime.now(),
           ) {
    if (resumeLogs != null) {
      _setLog.replaceAll(resumeLogs);
    }
    if (resumeState != null) {
      _armRestoredSession(resumeAfterRest);
      return;
    }
    if (!workout.hasStations) {
      state = state.copyWith(phase: SessionPhase.complete);
    } else {
      _enterBlock(0);
    }
  }

  @override
  final VoidCallback onWorkFinished;
  @override
  final VoidCallback onRestFinished;
  @override
  final VoidCallback onWorkoutFinished;

  @override
  WorkoutSessionState state;
  @override
  Timer? _ticker;

  @override
  _AfterRest _afterRest = _AfterRest.block;

  /// Counts empty timer stations so a circuit of them cannot loop forever.
  @override
  int _instantSkips = 0;

  final SessionSetLog _setLog = SessionSetLog();

  /// Elapsed seconds frozen while the app is in the background.
  int? _frozenElapsed;

  /// Reps logged so far, in the order sets were completed.
  List<SetLog> get setLogs => _setLog.logs;

  /// Time spent in this run. Does not grow while [freezeClock] is in effect.
  int get elapsedSeconds => _frozenElapsed ?? state.elapsedSeconds;

  /// Where a rest in progress will go when it ends.
  String get restContinuation => _afterRestName(_afterRest);

  /// The set just completed, while its rest is running. Null otherwise.
  SetLog? get restingSetLog {
    if (state.phase != SessionPhase.rest || _setLog.isEmpty) {
      return null;
    }
    if (state.currentExercise?.type != ExerciseType.sets) {
      return null;
    }
    return _setLog.last;
  }

  /// Changes the reps recorded for the set that just finished.
  void updateLastSetReps(int reps) {
    if (_setLog.updateLastReps(reps)) {
      notifyListeners();
    }
  }

  /// Changes reps and/or weight for any logged set of an exercise.
  void updateSetLog(
    String exerciseId,
    int setNumber, {
    int? reps,
    double? weightKg,
    int round = 1,
  }) {
    if (_setLog.update(
      exerciseId,
      setNumber,
      reps: reps,
      weightKg: weightKg,
      round: round,
    )) {
      notifyListeners();
    }
  }

  /// Logs for the station on screen, this round only.
  List<SetLog> get currentExerciseLogs {
    return _setLog.forExercise(
      state.currentExercise?.id,
      round: state.roundNumber,
    );
  }

  /// Last logged weight for this exercise, including earlier rounds.
  double previousWeightKg(String? exerciseId) {
    final logs = _setLog.forExercise(exerciseId);
    if (logs.isEmpty) {
      return 0;
    }
    return logs.last.weightKg ?? 0;
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

  /// Stops the countdown and holds [elapsedSeconds] until [thawClock].
  void freezeClock() {
    _frozenElapsed ??= state.elapsedSeconds;
    _stopTicker();
  }

  /// Continues the countdown from the held elapsed time, if it was running.
  void thawClock() {
    final frozen = _frozenElapsed;
    if (frozen == null) {
      return;
    }
    _frozenElapsed = null;
    state = state.copyWith(
      startedAt: DateTime.now().subtract(Duration(seconds: frozen)),
    );
    if (_shouldTick) {
      _startTicker();
    }
    notifyListeners();
  }

  /// Restart the whole workout from the first exercise.
  void restart() {
    if (!state.workout.hasStations) {
      return;
    }
    _frozenElapsed = null;
    _stopTicker();
    _afterRest = _AfterRest.block;
    _instantSkips = 0;
    _setLog.clear();
    state = WorkoutSessionState(
      workout: state.workout,
      blockIndex: 0,
      roundIndex: 0,
      exerciseIndex: 0,
      setIndex: 0,
      phase: SessionPhase.work,
      remainingSeconds: 0,
      isPaused: false,
      startedAt: DateTime.now(),
    );
    _enterBlock(0);
  }

  void _armRestoredSession(String? afterRest) {
    if (state.phase == SessionPhase.rest) {
      _afterRest = _afterRestFromName(afterRest ?? _inferredAfterRest());
    }
    if (_shouldTick) {
      _startTicker();
    }
  }

  bool get _shouldTick {
    if (state.isPaused || state.isComplete) {
      return false;
    }
    return state.phase == SessionPhase.work || state.phase == SessionPhase.rest;
  }

  /// Best guess when a saved rest did not record where it was going.
  String _inferredAfterRest() {
    final exercise = state.currentExercise;
    if (exercise == null) {
      return 'block';
    }
    if (exercise.type == ExerciseType.timer) {
      final rounds = exercise.sets ?? 1;
      if (state.setIndex < rounds - 1) {
        return 'timerRound';
      }
    } else {
      final sets = exercise.sets ?? 1;
      if (state.setIndex < sets - 1) {
        return 'set';
      }
    }
    return _stationExitName();
  }

  String _stationExitName() {
    final exit = planStationExit(
      workout: state.workout,
      blockIndex: state.blockIndex,
      roundIndex: state.roundIndex,
      exerciseIndex: state.exerciseIndex,
      restAfterLastSet: state.currentExercise?.type == ExerciseType.sets,
    );
    return switch (exit.destination) {
      StationDestination.station => 'station',
      StationDestination.round => 'round',
      StationDestination.block => 'block',
    };
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

    _setLog.add(
      SetLog(
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        setNumber: state.setNumber,
        reps: repsDone ?? exercise.reps ?? 0,
        weightKg: weightKg,
        round: state.roundNumber,
      ),
    );

    final totalSets = exercise.sets ?? 1;
    final isLastSet = state.setIndex >= totalSets - 1;
    if (isLastSet) {
      _beginStationExit(restAfterLastSet: true);
      return;
    }
    _startRest(exercise.restSeconds ?? 0, _AfterRest.set);
  }
}

/// Builds the timer place for a saved run, using [now] so closed time is dropped.
WorkoutSessionState stateFromProgress(
  InProgressWorkout progress,
  Workout workout,
  DateTime now,
) {
  return WorkoutSessionState(
    workout: workout,
    blockIndex: progress.blockIndex,
    roundIndex: progress.roundIndex,
    exerciseIndex: progress.exerciseIndex,
    setIndex: progress.setIndex,
    phase: _phaseFromName(progress.phase),
    remainingSeconds: progress.remainingSeconds,
    isPaused: progress.isPaused,
    startedAt: progress.resumedStartedAt(now),
  );
}

SessionPhase _phaseFromName(String raw) {
  for (final phase in SessionPhase.values) {
    if (phase.name == raw) {
      return phase;
    }
  }
  return SessionPhase.work;
}

String _afterRestName(_AfterRest after) {
  return switch (after) {
    _AfterRest.timerRound => 'timerRound',
    _AfterRest.set => 'set',
    _AfterRest.station => 'station',
    _AfterRest.round => 'round',
    _AfterRest.block => 'block',
  };
}

_AfterRest _afterRestFromName(String name) {
  return switch (name) {
    'timerRound' => _AfterRest.timerRound,
    'set' => _AfterRest.set,
    'station' => _AfterRest.station,
    'round' => _AfterRest.round,
    _ => _AfterRest.block,
  };
}
