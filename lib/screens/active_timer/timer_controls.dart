import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/skins.dart';
import '../../providers/settings_provider.dart';
import '../../services/workout_session_controller.dart';
import '../../widgets/skin_artwork.dart';

/// Standing characters beside Done.
const _doneMascotSize = 76.0;

/// One mascot beside Done when the skin has no partner.
const _soloMascotSize = 92.0;

/// Sitting characters beside Skip rest. Kept low so they stay near the button.
const _restSitSize = 56.0;

/// Lying pose beside Skip rest. Width follows the 16:9 rest pictures.
const _restMascotWidth = 136.0;
const _restMascotHeight = 76.0;

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
      return _doneButton(context, skin);
    }
    if (state.phase == SessionPhase.rest) {
      return _skipRestButton(skin);
    }
    return const SizedBox.shrink();
  }

  /// Woman on the left of Done, man on the right. One mascot stays on the right.
  Widget _doneButton(BuildContext context, AppSkin skin) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final label = state.setNumber >= state.totalSets
        ? 'Done'
        : 'Done / Next Set';
    final button = Expanded(
      child: _actionButton(label, onPrimary, theme, onCompleteSet),
    );
    if (skin.mascotSeatPartnerAsset != null) {
      return _donePair(button);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        button,
        if (skin.mascotSeatAsset != null) ...[
          const SizedBox(width: 8),
          const SkinMascot(seated: true, size: _soloMascotSize, pinned: false),
        ],
      ],
    );
  }

  Widget _donePair(Widget button) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SkinMascot(seated: true, size: _doneMascotSize, pinned: false),
        const SizedBox(width: 8),
        button,
        const SizedBox(width: 8),
        const SkinMascot(
          seated: true,
          size: _doneMascotSize,
          pinned: false,
          partner: true,
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    Color onPrimary,
    ThemeData theme,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Woman sits on the left of Skip rest, man on the right.
  Widget _skipRestButton(AppSkin skin) {
    final button = Expanded(
      child: SizedBox(
        height: 52,
        child: FilledButton.tonal(
          onPressed: onSkipRest,
          child: const Text('Skip rest'),
        ),
      ),
    );
    if (skin.mascotRestPartnerAsset != null) {
      return _restPair(button);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (skin.mascotRestAsset != null) ...[
          const SkinMascot(
            resting: true,
            width: _restMascotWidth,
            height: _restMascotHeight,
            pinned: false,
          ),
          const SizedBox(width: 8),
        ],
        button,
      ],
    );
  }

  Widget _restPair(Widget button) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SkinMascot(resting: true, size: _restSitSize, pinned: false),
        const SizedBox(width: 8),
        button,
        const SizedBox(width: 8),
        const SkinMascot(
          resting: true,
          size: _restSitSize,
          pinned: false,
          partner: true,
        ),
      ],
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
