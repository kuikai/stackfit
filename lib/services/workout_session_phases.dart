part of 'workout_session_controller.dart';

/// What to do when the current rest ends.
enum _AfterRest { timerRound, set, hold, station, round, block }

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
  void Function(int secondsLeft)? get onCountdown;

  DateTime _now();

  /// End of the rest that is running now. The countdown reads this, not ticks.
  DateTime? _restEndsAt;

  /// True after [freezeClock] while a rest is still on the wall clock.
  bool _restLeftRunning = false;

  /// Moment a hold read 0:00. Null while paused or not holding.
  DateTime? _holdStartedAt;

  /// True after [freezeClock] while a hold is still on the wall clock.
  bool _holdLeftRunning = false;

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
    if (exercise.type == ExerciseType.hold) {
      _beginHold();
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
      // A new exercise waits. Later rounds start in [_startNextTimerRound].
      state = state.copyWith(
        phase: SessionPhase.workReady,
        remainingSeconds: work,
        isPaused: false,
      );
      _stopTicker();
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
    _clearRestDeadline();
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
      case _AfterRest.hold:
        _beginHold(setIndex: state.setIndex + 1);
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
      _clearRestDeadline();
      _applyAfterRest(after);
      return;
    }
    _instantSkips = 0;
    _afterRest = after;
    _restEndsAt = _now().add(Duration(seconds: seconds));
    _restLeftRunning = false;
    state = state.copyWith(
      phase: SessionPhase.rest,
      remainingSeconds: seconds,
      isPaused: false,
    );
    _startTicker();
    notifyListeners();
    _noteCountdown(seconds);
  }

  /// Starts a hold at 0:00, or continues at [setIndex] for the next attempt.
  void _beginHold({int? setIndex}) {
    _instantSkips = 0;
    _holdLeftRunning = false;
    _holdStartedAt = _now();
    state = state.copyWith(
      setIndex: setIndex ?? state.setIndex,
      phase: SessionPhase.hold,
      remainingSeconds: 0,
      isPaused: false,
    );
    _startTicker();
    notifyListeners();
  }

  void _clearHoldClock() {
    _holdStartedAt = null;
    _holdLeftRunning = false;
  }

  /// Seconds on the hold clock right now.
  int _holdSecondsNow() {
    final started = _holdStartedAt;
    if (started == null || state.isPaused) {
      return state.remainingSeconds < 0 ? 0 : state.remainingSeconds;
    }
    final seconds = _now().difference(started).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  void _syncHold() {
    if (state.phase != SessionPhase.hold || state.isPaused) {
      return;
    }
    final elapsed = _holdSecondsNow();
    if (elapsed == state.remainingSeconds) {
      return;
    }
    state = state.copyWith(remainingSeconds: elapsed);
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
    _noteCountdown(work);
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

  void _clearRestDeadline() {
    _restEndsAt = null;
    _restLeftRunning = false;
  }

  void _startTicker() {
    _ticker?.cancel();
    // Work drops one second per tick, so it stays on a one-second timer.
    // Rest reads the wall clock and can tick faster without drifting.
    final step =
        state.phase == SessionPhase.rest || state.phase == SessionPhase.hold
        ? const Duration(milliseconds: 200)
        : const Duration(seconds: 1);
    _ticker = Timer.periodic(step, (_) => _onTick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  /// Moves the rest countdown onto the wall clock.
  /// Returns true while that rest is still running.
  bool _syncRest() {
    if (state.phase != SessionPhase.rest || state.isPaused) {
      return false;
    }
    final endsAt = _restEndsAt;
    if (endsAt == null) {
      return false;
    }
    final remaining = countdownSecondsLeft(endsAt, _now());
    if (remaining > 0) {
      if (remaining != state.remainingSeconds) {
        state = state.copyWith(remainingSeconds: remaining);
        notifyListeners();
        _noteCountdown(remaining);
      }
      return true;
    }
    _finishRest(playAlarm: true);
    _noteCountdown(0);
    return false;
  }

  void _onTick() {
    if (state.isPaused || state.isComplete) {
      return;
    }
    if (state.phase == SessionPhase.rest) {
      _syncRest();
      return;
    }
    if (state.phase == SessionPhase.hold) {
      _syncHold();
      return;
    }
    if (state.phase != SessionPhase.work) {
      return;
    }

    final previous = state.remainingSeconds;
    final next = previous - 1;
    if (next > 0) {
      state = state.copyWith(remainingSeconds: next);
      notifyListeners();
      _noteCountdown(next);
      return;
    }

    state = state.copyWith(remainingSeconds: 0);
    notifyListeners();
    _beginRestAfterWork();
    if (previous > 0) {
      _noteCountdown(0);
    }
  }

  /// A soft cue while 3, 2, or 1 is on screen, and a landing tone at 0.
  void _noteCountdown(int seconds) {
    if (seconds < 0 || seconds > 3) {
      return;
    }
    onCountdown?.call(seconds);
  }

  _AfterRest _afterRestFor(StationDestination destination) {
    return switch (destination) {
      StationDestination.station => _AfterRest.station,
      StationDestination.round => _AfterRest.round,
      StationDestination.block => _AfterRest.block,
    };
  }
}
