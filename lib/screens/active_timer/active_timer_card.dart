import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/models.dart';
import '../../services/workout_session_controller.dart';

/// The WORK / REST countdown, drawn on the background with no holder box.
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

    final showRound =
        exercise?.type == ExerciseType.timer &&
        state.totalSets > 1 &&
        (state.phase == SessionPhase.work || state.phase == SessionPhase.rest);
    final showSetRest =
        exercise?.type == ExerciseType.sets && state.phase == SessionPhase.rest;

    final countdown = Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            const SizedBox(height: 6),
            Text(
              showRound
                  ? 'Set ${state.setNumber} of ${state.totalSets}'
                  : _restCaption(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Expanded(child: _clock(context, exercise)),
        ],
      ),
    );

    return countdown;
  }

  /// Big time, shrunk to the space under the phase label so it never overflows.
  Widget _clock(BuildContext context, Exercise? exercise) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final face = state.phase == SessionPhase.setReady && exercise != null
        ? _SetPrompt(
            setNumber: state.setNumber,
            totalSets: state.totalSets,
            reps: exercise.reps,
          )
        : Text(
            AppUtils.formatDuration(state.remainingSeconds),
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 96,
              fontWeight: FontWeight.w800,
              letterSpacing: -3,
              height: 1,
              color: colorScheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          face,
          if (state.isPaused) ...[
            const SizedBox(height: 8),
            Text(
              'PAUSED',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// During rest after a set, the set coming up, or that the exercise is done.
  String _restCaption() {
    final next = state.setNumber + 1;
    if (next > state.totalSets) {
      return 'All ${state.totalSets} sets done';
    }
    return 'Next: set $next of ${state.totalSets}';
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
