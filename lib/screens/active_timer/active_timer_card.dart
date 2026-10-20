import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/workout_session_controller.dart';

/// The big WORK / REST / SET card with the countdown or set prompt.
class ActiveTimerCard extends StatelessWidget {
  const ActiveTimerCard({super.key, required this.state});

  final WorkoutSessionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exercise = state.currentExercise;

    final phaseLabel = switch (state.phase) {
      SessionPhase.work => 'WORK',
      SessionPhase.rest => 'REST',
      SessionPhase.setReady => 'SET',
      SessionPhase.complete => 'DONE',
    };

    final phaseColor = switch (state.phase) {
      SessionPhase.rest => colorScheme.secondary,
      _ => colorScheme.primary,
    };

    final showRound = exercise?.type == ExerciseType.timer &&
        state.totalSets > 1 &&
        (state.phase == SessionPhase.work || state.phase == SessionPhase.rest);
    final showSetRest =
        exercise?.type == ExerciseType.sets && state.phase == SessionPhase.rest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
            if (showRound || showSetRest) ...[
              const SizedBox(height: 10),
              Text(
                showRound
                    ? 'Set ${state.setNumber} of ${state.totalSets}'
                    : 'Next: set ${_nextSetLabel()}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Spacer(),
            if (state.phase == SessionPhase.setReady && exercise != null)
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
                  fontFeatures: const [FontFeature.tabularFigures()],
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
    );
  }

  /// During rest after a set, the set coming up (or "done" after the last).
  String _nextSetLabel() {
    final next = state.setNumber + 1;
    if (next > state.totalSets) {
      return '${state.totalSets} of ${state.totalSets} done';
    }
    return '$next of ${state.totalSets}';
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
