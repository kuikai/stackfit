import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/models.dart';
import '../../services/sound_service.dart';
import '../../services/workout_session_controller.dart';
import '../../widgets/set_tracker.dart';
import '../../widgets/skin_artwork.dart';
import 'active_timer_card.dart';
import 'workout_complete_screen.dart';

/// Side-by-side layout (timer left, set log right) from this width up.
const double _wideLayoutBreakpoint = 720;

class ActiveTimerScreen extends StatefulWidget {
  const ActiveTimerScreen({
    super.key,
    required this.workout,
  });

  final Workout workout;

  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  late final WorkoutSessionController _controller;
  final _sound = SoundService();
  bool _navigatedToComplete = false;

  /// What the user is entering for the set currently on screen.
  ActiveSetEntry _activeEntry = const ActiveSetEntry(reps: 0, weightKg: 0);
  int _entryExerciseIndex = -1;
  int _entrySetIndex = -1;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _controller = WorkoutSessionController(
      workout: widget.workout,
      onWorkFinished: _sound.playWorkEnd,
      onRestFinished: _sound.playRestEnd,
      onWorkoutFinished: () {},
    );
    _controller.addListener(_onSessionUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.state.isComplete) {
        _openComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onSessionUpdate);
    _controller.disposeController();
    WakelockPlus.disable();
    super.dispose();
  }

  void _onSessionUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_controller.state.isComplete) {
      _openComplete();
    }
  }

  /// Prefills reps from the plan and weight from the previous set whenever a
  /// new set comes up.
  void _syncEntryForCurrentSet() {
    final state = _controller.state;
    if (state.phase != SessionPhase.setReady) {
      return;
    }
    if (_entryExerciseIndex == state.exerciseIndex &&
        _entrySetIndex == state.setIndex) {
      return;
    }
    _entryExerciseIndex = state.exerciseIndex;
    _entrySetIndex = state.setIndex;

    final logs = _controller.currentExerciseLogs;
    final previousWeight = logs.isEmpty ? 0.0 : (logs.last.weightKg ?? 0.0);
    _activeEntry = ActiveSetEntry(
      reps: state.currentExercise?.reps ?? 0,
      weightKg: previousWeight,
    );
  }

  void _completeSet() {
    _controller.completeSet(
      repsDone: _activeEntry.reps,
      weightKg: _activeEntry.weightKg > 0 ? _activeEntry.weightKg : null,
    );
  }

  void _openComplete() {
    if (_navigatedToComplete || !mounted) {
      return;
    }
    _navigatedToComplete = true;
    final state = _controller.state;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutCompleteScreen(
          args: WorkoutCompleteArgs(
            workout: state.workout,
            durationSeconds: state.elapsedSeconds,
            setLogs: _controller.setLogs,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncEntryForCurrentSet();
    final state = _controller.state;
    final exercise = state.currentExercise;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final showTracker = exercise?.type == ExerciseType.sets &&
        (state.phase == SessionPhase.setReady ||
            state.phase == SessionPhase.rest);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        leading: IconButton(
          tooltip: 'Stop',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Stack(
        children: [
          const SkinArtworkBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                children: [
                  Text(
                    exercise == null
                        ? 'Workout'
                        : 'Exercise ${state.exerciseNumber} of ${state.exerciseCount}',
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
                      timer: ActiveTimerCard(state: state),
                      tracker: showTracker && exercise != null
                          ? _buildTracker(exercise, state)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildPrimaryAction(state, theme, colorScheme),
                  const SizedBox(height: 12),
                  _buildSecondaryControls(state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Timer and tracker side by side on wide screens, stacked otherwise.
  Widget _buildMainArea({required Widget timer, Widget? tracker}) {
    if (tracker == null) {
      return timer;
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
                child: SingleChildScrollView(child: tracker),
              ),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: timer),
            const SizedBox(height: 12),
            Flexible(child: SingleChildScrollView(child: tracker)),
          ],
        );
      },
    );
  }

  Widget _buildTracker(Exercise exercise, WorkoutSessionState state) {
    final isResting = state.phase == SessionPhase.rest;
    final restingLog = _controller.restingSetLog;
    final activeSetNumber =
        isResting ? (restingLog?.setNumber ?? state.setNumber) : state.setNumber;

    return SetTracker(
      exercise: exercise,
      logs: _controller.currentExerciseLogs,
      activeSetNumber: activeSetNumber,
      activeEntry: _activeEntry,
      isResting: isResting,
      onActiveEntryChanged: (entry) => setState(() => _activeEntry = entry),
      onLoggedSetChanged: (setNumber, {reps, weightKg}) {
        _controller.updateSetLog(
          exercise.id,
          setNumber,
          reps: reps,
          weightKg: weightKg,
        );
      },
    );
  }

  Widget _buildPrimaryAction(
    WorkoutSessionState state,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (state.phase == SessionPhase.setReady) {
      return SizedBox(
        width: double.infinity,
        height: 60,
        child: FilledButton(
          onPressed: _completeSet,
          child: Text(
            state.setNumber >= state.totalSets ? 'Done' : 'Done / Next Set',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onPrimary,
            ),
          ),
        ),
      );
    }
    if (state.phase == SessionPhase.rest) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.tonal(
          onPressed: _controller.skipRest,
          child: const Text('Skip rest'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSecondaryControls(WorkoutSessionState state) {
    final isSetReady = state.phase == SessionPhase.setReady;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSetReady ? null : _controller.togglePause,
                icon: Icon(
                  state.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                ),
                label: Text(state.isPaused ? 'Resume' : 'Pause'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isSetReady ? _completeSet : _controller.skipCurrent,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Skip'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _controller.restart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
