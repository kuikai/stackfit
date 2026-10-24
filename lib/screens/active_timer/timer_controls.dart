import 'package:flutter/material.dart';

import '../../services/workout_session_controller.dart';

/// Done / Skip rest, shown under the countdown.
class TimerPrimaryAction extends StatelessWidget {
  const TimerPrimaryAction({
    super.key,
    required this.state,
    required this.onCompleteSet,
    required this.onSkipRest,
  });

  final WorkoutSessionState state;
  final VoidCallback onCompleteSet;
  final VoidCallback onSkipRest;

  @override
  Widget build(BuildContext context) {
    if (state.phase == SessionPhase.setReady) {
      return _doneButton(context);
    }
    if (state.phase == SessionPhase.rest) {
      return _skipRestButton();
    }
    return const SizedBox.shrink();
  }

  Widget _doneButton(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final label = state.setNumber >= state.totalSets
        ? 'Done'
        : 'Done / Next Set';
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton(
        onPressed: onCompleteSet,
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _skipRestButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.tonal(
        onPressed: onSkipRest,
        child: const Text('Skip rest'),
      ),
    );
  }
}

/// Pause, skip, reset, and stop.
class TimerSecondaryControls extends StatelessWidget {
  const TimerSecondaryControls({
    super.key,
    required this.state,
    required this.onPause,
    required this.onSkip,
    required this.onRestart,
    required this.onStop,
  });

  final WorkoutSessionState state;
  final VoidCallback onPause;
  final VoidCallback onSkip;
  final VoidCallback onRestart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    if (state.phase == SessionPhase.setReady) {
      return Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onRestart,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPause,
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
                onPressed: onSkip,
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
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onStop,
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
