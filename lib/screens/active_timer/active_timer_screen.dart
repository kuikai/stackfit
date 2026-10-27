import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/models.dart';
import '../../providers/completed_sessions_provider.dart';
import '../../providers/in_progress_provider.dart';
import '../../services/previous_set_log.dart';
import '../../services/sound_service.dart';
import '../../services/workout_session_controller.dart';
import '../../widgets/set_tracker.dart';
import 'active_timer_card.dart';
import 'timer_controls.dart';
import 'workout_complete_screen.dart';

/// Side-by-side layout (timer left, set log right) from this width up.
const double _wideLayoutBreakpoint = 720;

class ActiveTimerScreen extends ConsumerStatefulWidget {
  const ActiveTimerScreen({
    super.key,
    required this.workout,
    this.progress,
    this.origin,
  });

  final Workout workout;

  /// Saved place to continue. Null starts from the first exercise.
  final InProgressWorkout? progress;

  /// Set when this run was started from a plan day.
  final String? origin;

  @override
  ConsumerState<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends ConsumerState<ActiveTimerScreen>
    with WidgetsBindingObserver {
  late final WorkoutSessionController _controller;
  final _sound = SoundService();
  bool _navigatedToComplete = false;
  bool _finished = false;
  bool _announcedLeave = false;
  bool _suppressPersist = false;
  String? _lastSignature;

  /// What the user is entering for the set currently on screen.
  ActiveSetEntry _activeEntry = const ActiveSetEntry(reps: 0, weightKg: 0);
  bool _entryEdited = false;
  int _entryBlockIndex = -1;
  int _entryRoundIndex = -1;
  int _entryExerciseIndex = -1;
  int _entrySetIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _controller = _createController();
    _restoreDraftEntry();
    _controller.addListener(_onSessionUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _lastSignature = _capture().changeSignature;
      if (_controller.state.isComplete) {
        _openComplete();
      }
    });
  }

  WorkoutSessionController _createController() {
    final progress = widget.progress;
    final resume = progress != null && progress.canResume ? progress : null;
    return WorkoutSessionController(
      workout: widget.workout,
      onWorkFinished: _sound.playWorkEnd,
      onRestFinished: _sound.playRestEnd,
      onWorkoutFinished: () {},
      resumeState: resume == null
          ? null
          : stateFromProgress(resume, widget.workout, DateTime.now()),
      resumeLogs: resume?.setLogs,
      resumeAfterRest: resume?.afterRest,
    );
  }

  void _restoreDraftEntry() {
    final progress = widget.progress;
    if (progress == null || !progress.draftEdited) {
      return;
    }
    if (progress.phase != 'setReady') {
      return;
    }
    _activeEntry = ActiveSetEntry(
      reps: progress.draftReps,
      weightKg: progress.draftWeightKg,
    );
    _entryEdited = true;
    _entryBlockIndex = progress.blockIndex;
    _entryRoundIndex = progress.roundIndex;
    _entryExerciseIndex = progress.exerciseIndex;
    _entrySetIndex = progress.setIndex;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onSessionUpdate);
    if (!_finished) {
      _persist(force: true);
    }
    _controller.disposeController();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final background =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    if (background) {
      _controller.freezeClock();
      _persist(force: true);
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _controller.thawClock();
    }
  }

  void _onSessionUpdate() {
    if (!mounted) {
      return;
    }
    if (_controller.state.isComplete) {
      setState(() {});
      _openComplete();
      return;
    }
    if (!_suppressPersist) {
      _alignEntry(ref.read(completedSessionsProvider));
      _persist();
    }
    setState(() {});
  }

  /// Prefills reps and weight when a new set comes up.
  void _alignEntry(List<CompletedSession> history) {
    final state = _controller.state;
    if (state.phase != SessionPhase.setReady) {
      return;
    }
    final sameSet =
        _entryBlockIndex == state.blockIndex &&
        _entryRoundIndex == state.roundIndex &&
        _entryExerciseIndex == state.exerciseIndex &&
        _entrySetIndex == state.setIndex;
    if (sameSet && _entryEdited) {
      return;
    }
    _entryEdited = false;
    _entryBlockIndex = state.blockIndex;
    _entryRoundIndex = state.roundIndex;
    _entryExerciseIndex = state.exerciseIndex;
    _entrySetIndex = state.setIndex;
    final exercise = state.currentExercise;
    final previous = exercise == null
        ? const <SetLog>[]
        : previousLogsForExercise(
            sessions: history,
            workoutId: widget.workout.id,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            round: state.roundNumber,
          );
    final start = startingEntryForSet(
      previousLogs: previous,
      setNumber: state.setNumber,
      plannedReps: exercise?.reps,
      sessionWeightKg: _controller.previousWeightKg(exercise?.id),
    );
    _activeEntry = ActiveSetEntry(reps: start.reps, weightKg: start.weightKg);
  }

  void _onEntryChanged(ActiveSetEntry entry) {
    setState(() {
      _activeEntry = entry;
      _entryEdited = true;
    });
    _persist();
  }

  void _completeSet() {
    _controller.completeSet(
      repsDone: _activeEntry.reps,
      weightKg: _activeEntry.weightKg > 0 ? _activeEntry.weightKg : null,
    );
  }

  void _restart() {
    _suppressPersist = true;
    _entryEdited = false;
    _entryBlockIndex = -1;
    _entryRoundIndex = -1;
    _entryExerciseIndex = -1;
    _entrySetIndex = -1;
    _controller.restart();
    _suppressPersist = false;
    _lastSignature = _capture().changeSignature;
    unawaited(ref.read(inProgressProvider.notifier).discard(widget.workout.id));
  }

  void _leave() {
    if (_finished || _announcedLeave || !mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  /// Stop, the close button, system back, and the swipe-back gesture all pop.
  void _announceLeave() {
    if (_finished || _announcedLeave) {
      return;
    }
    _announcedLeave = true;
    final kept = _persist(force: true);
    if (!kept || !mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Progress saved')));
  }

  void _openComplete() {
    if (_navigatedToComplete || !mounted) {
      return;
    }
    _navigatedToComplete = true;
    _finished = true;
    final state = _controller.state;
    final logs = List<SetLog>.of(_controller.setLogs);
    final duration = _controller.elapsedSeconds;
    unawaited(ref.read(inProgressProvider.notifier).discard(widget.workout.id));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutCompleteScreen(
          args: WorkoutCompleteArgs(
            workout: state.workout,
            durationSeconds: duration,
            setLogs: logs,
          ),
        ),
      ),
    );
  }

  InProgressWorkout _capture() {
    final state = _controller.state;
    final onOpenSet = state.phase == SessionPhase.setReady;
    return InProgressWorkout(
      workout: widget.workout,
      origin: widget.origin,
      blockIndex: state.blockIndex,
      roundIndex: state.roundIndex,
      exerciseIndex: state.exerciseIndex,
      setIndex: state.setIndex,
      phase: state.phase.name,
      remainingSeconds: state.remainingSeconds,
      isPaused: state.isPaused,
      elapsedSeconds: _controller.elapsedSeconds,
      setLogs: _controller.setLogs,
      draftEdited: onOpenSet && _entryEdited,
      draftReps: _activeEntry.reps,
      draftWeightKg: _activeEntry.weightKg,
      afterRest: state.phase == SessionPhase.rest
          ? _controller.restContinuation
          : null,
      savedAt: DateTime.now(),
    );
  }

  /// Writes the run when the place or the logs changed. Returns true if kept.
  bool _persist({bool force = false}) {
    if (_finished || _suppressPersist) {
      return false;
    }
    final run = _capture();
    final signature = run.changeSignature;
    if (!force && signature == _lastSignature) {
      return run.hasProgress;
    }
    _lastSignature = signature;
    final notifier = ref.read(inProgressProvider.notifier);
    if (!run.hasProgress) {
      unawaited(notifier.discard(run.workout.id));
      return false;
    }
    unawaited(notifier.save(run));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(completedSessionsProvider);
    _alignEntry(history);
    final state = _controller.state;
    final exercise = state.currentExercise;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showTracker =
        exercise?.type == ExerciseType.sets &&
        (state.phase == SessionPhase.setReady ||
            state.phase == SessionPhase.rest);
    final showTimerCard = state.phase != SessionPhase.setReady;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _announceLeave();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workout.name),
          leading: IconButton(
            tooltip: 'Stop',
            onPressed: _leave,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              children: [
                Text(
                  exercise == null ? 'Workout' : state.progressLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  exercise?.name ?? 'Complete',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildMainArea(
                    timer: showTimerCard ? ActiveTimerCard(state: state) : null,
                    tracker: showTracker && exercise != null
                        ? _buildTracker(exercise, state, history)
                        : null,
                  ),
                ),
                const SizedBox(height: 18),
                TimerPrimaryAction(
                  state: state,
                  onCompleteSet: _completeSet,
                  onSkipRest: _controller.skipRest,
                ),
                const SizedBox(height: 12),
                TimerSecondaryControls(
                  state: state,
                  onPause: _controller.togglePause,
                  onSkip: state.phase == SessionPhase.setReady
                      ? _completeSet
                      : _controller.skipCurrent,
                  onRestart: _restart,
                  onStop: _leave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Timer and tracker side by side on wide screens, stacked otherwise.
  Widget _buildMainArea({Widget? timer, Widget? tracker}) {
    if (tracker == null) {
      return timer ?? const SizedBox.shrink();
    }
    if (timer == null) {
      return Align(alignment: Alignment.topCenter, child: tracker);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideLayoutBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: timer),
              const SizedBox(width: 16),
              SizedBox(
                width: 340,
                child: Align(alignment: Alignment.topCenter, child: tracker),
              ),
            ],
          );
        }
        return _phoneStack(timer, tracker);
      },
    );
  }

  /// Clock on top, log underneath. Both get a real height so the time can
  /// shrink and the reps row stays below the set list.
  Widget _phoneStack(Widget timer, Widget tracker) {
    return Column(
      children: [
        Expanded(flex: 4, child: timer),
        const SizedBox(height: 8),
        Expanded(flex: 5, child: tracker),
      ],
    );
  }

  Widget _buildTracker(
    Exercise exercise,
    WorkoutSessionState state,
    List<CompletedSession> history,
  ) {
    final isResting = state.phase == SessionPhase.rest;
    final restingLog = _controller.restingSetLog;
    final activeSetNumber = isResting
        ? (restingLog?.setNumber ?? state.setNumber)
        : state.setNumber;

    return SetTracker(
      exercise: exercise,
      logs: _controller.currentExerciseLogs,
      previousLogs: previousLogsForExercise(
        sessions: history,
        workoutId: widget.workout.id,
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        round: state.roundNumber,
      ),
      activeSetNumber: activeSetNumber,
      activeEntry: _activeEntry,
      isResting: isResting,
      onActiveEntryChanged: _onEntryChanged,
      onLoggedSetChanged: (setNumber, {reps, weightKg}) {
        _controller.updateSetLog(
          exercise.id,
          setNumber,
          round: state.roundNumber,
          reps: reps,
          weightKg: weightKg,
        );
      },
    );
  }
}
