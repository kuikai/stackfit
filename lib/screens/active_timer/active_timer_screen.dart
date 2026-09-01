import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/sound_service.dart';
import '../../services/workout_session_controller.dart';
import 'workout_complete_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _controller = WorkoutSessionController(
      workout: widget.workout,
      onWorkFinished: () => _sound.playWorkEnd(),
      onRestFinished: () => _sound.playRestEnd(),
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
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final exercise = state.currentExercise;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final phaseLabel = switch (state.phase) {
      SessionPhase.work => 'WORK',
      SessionPhase.rest => 'REST',
      SessionPhase.setReady => 'SET',
      SessionPhase.complete => 'DONE',
    };

    final phaseColor = switch (state.phase) {
      SessionPhase.work => colorScheme.primary,
      SessionPhase.rest => colorScheme.secondary,
      SessionPhase.setReady => colorScheme.primary,
      SessionPhase.complete => colorScheme.primary,
    };

    final showRound = exercise?.type == ExerciseType.timer &&
        state.totalSets > 1 &&
        (state.phase == SessionPhase.work || state.phase == SessionPhase.rest);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        leading: IconButton(
          tooltip: 'Stop',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: phaseColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            phaseLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: phaseColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.4,
                            ),
                          ),
                        ),
                        if (showRound) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Set ${state.setNumber} of ${state.totalSets}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (state.phase == SessionPhase.setReady &&
                            exercise != null)
                          _SetPrompt(
                            setNumber: state.setNumber,
                            totalSets: state.totalSets,
                            reps: exercise.reps,
                          )
                        else
                          Text(
                            AppUtils.formatDuration(state.remainingSeconds),
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: 96,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -3,
                              height: 1,
                              color: colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        if (state.isPaused) ...[
                          const SizedBox(height: 14),
                          Text(
                            'PAUSED',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ],
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (state.phase == SessionPhase.setReady)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton(
                    onPressed: _controller.completeSet,
                    child: Text(
                      state.setNumber >= state.totalSets
                          ? 'Done'
                          : 'Done / Next Set',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                )
              else if (state.phase == SessionPhase.rest)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.tonal(
                    onPressed: _controller.skipRest,
                    child: const Text('Skip rest'),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.phase == SessionPhase.setReady
                          ? null
                          : _controller.togglePause,
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
                      onPressed: _controller.skipCurrent,
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
          ),
        ),
      ),
    );
  }
}

class _SetPrompt extends StatelessWidget {
  const _SetPrompt({
    required this.setNumber,
    required this.totalSets,
    required this.reps,
  });

  final int setNumber;
  final int totalSets;
  final int? reps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          'Set $setNumber of $totalSets',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            fontSize: 42,
          ),
          textAlign: TextAlign.center,
        ),
        if (reps != null) ...[
          const SizedBox(height: 10),
          Text(
            '$reps reps',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
