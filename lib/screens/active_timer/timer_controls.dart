import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_provider.dart';
import '../../services/workout_session_controller.dart';
import '../../widgets/skin_artwork.dart';

/// How far the sitting chibi stands above the Done button.
const _seatLift = 108.0;

/// How far the resting chibi stands above the Skip rest button.
const _restLift = 96.0;

/// Done / Skip rest, shown under the countdown.
class TimerPrimaryAction extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(settingsProvider).skin;
    if (state.phase == SessionPhase.setReady) {
      final lift = skin.mascotSeatAsset == null ? 0.0 : _seatLift;
      return _doneButton(context, lift);
    }
    if (state.phase == SessionPhase.rest) {
      final lift = skin.mascotRestAsset == null ? 0.0 : _restLift;
      return _skipRestButton(lift);
    }
    return const SizedBox.shrink();
  }

  Widget _doneButton(BuildContext context, double mascotLift) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final label = state.setNumber >= state.totalSets
        ? 'Done'
        : 'Done / Next Set';
    return Padding(
      padding: EdgeInsets.only(top: mascotLift),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
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
            ),
            if (mascotLift > 0)
              Positioned(
                right: 6,
                top: -mascotLift,
                child: const SkinMascot(seated: true, size: 148, pinned: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _skipRestButton(double mascotLift) {
    return Padding(
      padding: EdgeInsets.only(top: mascotLift),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: FilledButton.tonal(
                onPressed: onSkipRest,
                child: const Text('Skip rest'),
              ),
            ),
            if (mascotLift > 0)
              const Positioned(
                left: 0,
                right: 0,
                top: -_restLift,
                child: Center(
                  child: SkinMascot(resting: true, width: 260, pinned: false),
                ),
              ),
          ],
        ),
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
