import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/skins.dart';
import '../../providers/settings_provider.dart';
import '../../services/workout_session_controller.dart';
import '../../widgets/skin_artwork.dart';

/// How far a solo mascot sits above the Done button. The picture hangs
/// past this so her seat lands on the bar.
const _seatLift = 108.0;

/// Sitting picture on Done.
const _seatMascotSize = 148.0;

/// Standing pair beside Done (companion and trainer).
const _doneMascotSize = 76.0;

/// How far a solo rest pose sits above Skip rest.
const _restLift = 96.0;

/// Lying pose across Skip rest.
const _restPoseWidth = 260.0;

/// Sitting pair beside Skip rest. Kept low so they stay near the button.
const _restSitSize = 56.0;

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

  /// One mascot perches on the right of Done. A pair stands on either side.
  Widget _doneButton(BuildContext context, AppSkin skin) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    final label = state.setNumber >= state.totalSets
        ? 'Done'
        : 'Done / Next Set';
    if (skin.mascotSeatPartnerAsset != null) {
      return _donePair(
        Expanded(child: _actionButton(label, onPrimary, theme, onCompleteSet)),
      );
    }
    return _doneSolo(label, onPrimary, theme, skin.mascotSeatAsset != null);
  }

  /// Full-width bar. The mascot overlaps the top-right edge.
  Widget _doneSolo(
    String label,
    Color onPrimary,
    ThemeData theme,
    bool seated,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: seated ? _seatLift : 0),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _actionButton(label, onPrimary, theme, onCompleteSet),
            ),
            if (seated)
              const Positioned(
                right: 6,
                top: -_seatLift,
                child: SkinMascot(
                  seated: true,
                  size: _seatMascotSize,
                  pinned: false,
                ),
              ),
          ],
        ),
      ),
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

  /// One mascot lies across Skip rest. A pair sits on either side.
  Widget _skipRestButton(AppSkin skin) {
    if (skin.mascotRestPartnerAsset != null) {
      return _restPair(_restButton());
    }
    if (skin.mascotRestAsset == null) {
      return _restButton(expand: false);
    }
    return _restSolo();
  }

  Widget _restButton({bool expand = true}) {
    final button = SizedBox(
      height: 52,
      width: expand ? null : double.infinity,
      child: FilledButton.tonal(
        onPressed: onSkipRest,
        child: const Text('Skip rest'),
      ),
    );
    if (!expand) {
      return button;
    }
    return Expanded(child: button);
  }

  /// Full-width bar. The lying pose overlaps the top edge.
  Widget _restSolo() {
    return Padding(
      padding: const EdgeInsets.only(top: _restLift),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: _restButton(expand: false)),
            const Positioned(
              left: 0,
              right: 0,
              top: -_restLift,
              child: Center(
                child: SkinMascot(
                  resting: true,
                  width: _restPoseWidth,
                  pinned: false,
                ),
              ),
            ),
          ],
        ),
      ),
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
