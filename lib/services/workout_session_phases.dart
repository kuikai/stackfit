part of 'workout_session_controller.dart';

/// What to do when the current rest ends.
enum _AfterRest { timerRound, set, station, round, block }

mixin WorkoutSessionPhases on ChangeNotifier {
  WorkoutSessionState get state;
  set state(WorkoutSessionState value);
  Timer? get _ticker;
  set _ticker(Timer? value);
  _AfterRest get _afterRest;
  set _afterRest(_AfterRest value);
  int get _instantSkips;
  set _instantSkips(int value);
  VoidCallback get onWorkFinished;
  VoidCallback get onRestFinished;
  VoidCallback get onWorkoutFinished;

  void _enterBlock(int index) {
    final blocks = state.workout.blocks;
    if (index >= blocks.length) {
      _completeWorkout();
      return;
    }
    final block = blocks[index];
    if (block is CircuitBlock && block.circuit.exercises.isEmpty) {
      _enterBlock(index + 1);
      return;
    }
    _openExercise(blockIndex: index, roundIndex: 0, exerciseIndex: 0);
  }

  void _openExercise({
    required int blockIndex,
    required int roundIndex,
    required int exerciseIndex,
  }) {
    state = state.copyWith(
      blockIndex: blockIndex,
      roundIndex: roundIndex,
      exerciseIndex: exerciseIndex,
      setIndex: 0,
      isPaused: false,
    );
    final exercise = state.currentExercise;
    if (exercise == null) {
      _enterBlock(blockIndex + 1);
      return;
    }
    if (exercise.type == ExerciseType.timer) {
      _armTimer(exercise);
      return;
    }
    _instantSkips = 0;
    state = state.copyWith(
      phase: SessionPhase.setReady,
      remainingSeconds: 0,
      isPaused: false,
    );
    _stopTicker();
    notifyListeners();
  }

  void _armTimer(Exercise exercise) {
    final work = exercise.workSeconds ?? 0;
    final rest = exercise.restSeconds ?? 0;
    if (work <= 0 && rest <= 0) {
      _instantSkips++;
      if (_instantSkips > 30) {
        _completeWorkout();
        return;
      }
      _beginStationExit(restAfterLastSet: false);
      return;
    }
    _instantSkips = 0;
    if (work > 0) {
      state = state.copyWith(
        phase: SessionPhase.work,
        remainingSeconds: work,
        isPaused: false,
      );
      _startTicker();
      notifyListeners();
      return;
    }
    _startRest(rest, _AfterRest.timerRound);
  }

  void _beginRestAfterWork() {
    onWorkFinished();
    final exercise = state.currentExercise;
    if (exercise == null) {
      _enterBlock(state.blockIndex + 1);
      return;
    }
    if (exercise.type == ExerciseType.timer) {
      _afterTimerWork(exercise);
      return;
    }
    _afterSetsFallback(exercise);
  }

  void _afterTimerWork(Exercise exercise) {
    final rest = exercise.restSeconds ?? 0;
    final totalRounds = exercise.sets ?? 1;
    final isLastRound = state.setIndex >= totalRounds - 1;
    if (!isLastRound) {
      if (rest > 0) {
        _startRest(rest, _AfterRest.timerRound);
        return;
      }
      _startNextTimerRound();
      return;
    }
    _beginStationExit(restAfterLastSet: false);
  }

  /// Sets exercises normally leave through [completeSet]. This covers a skip
  /// that arrives while a sets exercise is somehow in the work phase.
  void _afterSetsFallback(Exercise exercise) {
    final totalSets = exercise.sets ?? 1;
    final isLastSet = state.setIndex >= totalSets - 1;
    if (!isLastSet) {
      _startRest(exercise.restSeconds ?? 0, _AfterRest.set);
      return;
    }
    _beginStationExit(restAfterLastSet: true);
  }

  void _beginStationExit({required bool restAfterLastSet}) {
    final exit = planStationExit(
      workout: state.workout,
      blockIndex: state.blockIndex,
      roundIndex: state.roundIndex,
      exerciseIndex: state.exerciseIndex,
      restAfterLastSet: restAfterLastSet,
    );
    _startRest(exit.restSeconds, _afterRestFor(exit.destination));
  }

  void _finishRest({required bool playAlarm}) {
    if (playAlarm) {
      onRestFinished();
    }
    final after = _afterRest;
    _afterRest = _AfterRest.block;
    _applyAfterRest(after);
  }

  void _applyAfterRest(_AfterRest after) {
    switch (after) {
      case _AfterRest.timerRound:
        _startNextTimerRound();
      case _AfterRest.set:
        state = state.copyWith(
          setIndex: state.setIndex + 1,
          phase: SessionPhase.setReady,
          remainingSeconds: 0,
          isPaused: false,
        );
        _stopTicker();
        notifyListeners();
      case _AfterRest.station:
        _openExercise(
          blockIndex: state.blockIndex,
          roundIndex: state.roundIndex,
          exerciseIndex: state.exerciseIndex + 1,
        );
      case _AfterRest.round:
        _openExercise(
          blockIndex: state.blockIndex,
          roundIndex: state.roundIndex + 1,
          exerciseIndex: 0,
        );
      case _AfterRest.block:
        _enterBlock(state.blockIndex + 1);
    }
  }

  void _startRest(int seconds, _AfterRest after) {
    if (seconds <= 0) {
      _applyAfterRest(after);
      return;
    }
    _instantSkips = 0;
    _afterRest = after;
    state = state.copyWith(
      phase: SessionPhase.rest,
      remainingSeconds: seconds,
      isPaused: false,
    );
    _startTicker();
    notifyListeners();
  }

  void _startNextTimerRound() {
    final exercise = state.currentExercise;
    final work = exercise?.workSeconds ?? 0;
    final nextRound = state.setIndex + 1;
    final totalRounds = exercise?.sets ?? 1;
    if (nextRound >= totalRounds || work <= 0) {
      _beginStationExit(restAfterLastSet: false);
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

  _AfterRest _afterRestFor(StationDestination destination) {
    return switch (destination) {
      StationDestination.station => _AfterRest.station,
      StationDestination.round => _AfterRest.round,
      StationDestination.block => _AfterRest.block,
    };
  }
}
