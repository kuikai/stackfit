import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/tabata_clock.dart';
import '../../providers/sound_provider.dart';
import '../../services/sound_service.dart';
import '../../services/workout_session_controller.dart';
import '../../widgets/number_stepper.dart';
import '../active_timer/active_timer_card.dart';
import '../active_timer/timer_controls.dart';

/// Tabata clock. Opens ready at 20/10/8 and does not save a workout.
class TabataScreen extends ConsumerStatefulWidget {
  const TabataScreen({super.key});

  @override
  ConsumerState<TabataScreen> createState() => _TabataScreenState();
}

class _TabataScreenState extends ConsumerState<TabataScreen>
    with WidgetsBindingObserver {
  late final SoundService _sound;
  WorkoutSessionController? _clock;
  int _work = TabataClock.classicWorkSeconds;
  int _rest = TabataClock.classicRestSeconds;
  int _rounds = TabataClock.classicRounds;

  @override
  void initState() {
    super.initState();
    _sound = ref.read(soundServiceProvider);
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dropClock();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final clock = _clock;
    if (clock == null) {
      return;
    }
    final background =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    if (background) {
      clock.freezeClock();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      clock.thawClock();
    }
  }

  bool get _isClassic {
    return _work == TabataClock.classicWorkSeconds &&
        _rest == TabataClock.classicRestSeconds &&
        _rounds == TabataClock.classicRounds;
  }

  /// Created only when Start is pressed. The workout clock waits on its own
  /// Start, so this one begins the first round immediately.
  void _start() {
    unawaited(_sound.prime());
    final clock = WorkoutSessionController(
      workout: TabataClock.build(
        workSeconds: _work,
        restSeconds: _rest,
        rounds: _rounds,
      ),
      onWorkFinished: () {},
      onRestFinished: () {},
      onCountdown: (seconds) => unawaited(_sound.playCountdown(seconds)),
      onWorkoutFinished: () {},
    );
    clock.startWork();
    clock.addListener(_onClock);
    setState(() => _clock = clock);
  }

  void _onClock() {
    if (mounted) {
      setState(() {});
    }
  }

  void _stopToReady() {
    _dropClock();
    setState(() {});
  }

  void _dropClock() {
    final clock = _clock;
    if (clock == null) {
      return;
    }
    clock.removeListener(_onClock);
    clock.disposeController();
    _clock = null;
  }

  void _useClassic() {
    setState(() {
      _work = TabataClock.classicWorkSeconds;
      _rest = TabataClock.classicRestSeconds;
      _rounds = TabataClock.classicRounds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clock = _clock;
    final state = clock?.state ?? _readyFace();
    final running = clock != null && !state.isComplete;
    final finished = state.isComplete;

    return Scaffold(
      appBar: AppBar(title: const Text('Tabata')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            children: [
              Expanded(
                child: ActiveTimerCard(state: state, countLabel: 'Round'),
              ),
              if (clock == null) _setup(),
              if (clock != null &&
                  running &&
                  state.phase == SessionPhase.rest) ...[
                const SizedBox(height: 12),
                TimerPrimaryAction(
                  state: state,
                  onStart: () {},
                  onCompleteSet: () {},
                  onCompleteHold: () {},
                  onSkipRest: clock.skipRest,
                ),
              ],
              const SizedBox(height: 12),
              _actions(running: running, finished: finished, clock: clock),
            ],
          ),
        ),
      ),
    );
  }

  WorkoutSessionState _readyFace() {
    return WorkoutSessionState(
      workout: TabataClock.build(
        workSeconds: _work,
        restSeconds: _rest,
        rounds: _rounds,
      ),
      blockIndex: 0,
      roundIndex: 0,
      exerciseIndex: 0,
      setIndex: 0,
      phase: SessionPhase.work,
      remainingSeconds: _work,
      isPaused: false,
      startedAt: DateTime.now(),
    );
  }

  Widget _setup() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _stepper(
              label: 'Work',
              unit: 'sec',
              value: _work,
              min: TabataClock.minWorkSeconds,
              max: TabataClock.maxWorkSeconds,
              step: 5,
              onChanged: (value) => setState(() => _work = value),
            ),
            const SizedBox(width: 8),
            _stepper(
              label: 'Rest',
              unit: 'sec',
              value: _rest,
              min: TabataClock.minRestSeconds,
              max: TabataClock.maxRestSeconds,
              step: 5,
              onChanged: (value) => setState(() => _rest = value),
            ),
            const SizedBox(width: 8),
            _stepper(
              label: 'Rounds',
              value: _rounds,
              min: TabataClock.minRounds,
              max: TabataClock.maxRounds,
              step: 1,
              onChanged: (value) => setState(() => _rounds = value),
            ),
          ],
        ),
        TextButton(
          onPressed: _isClassic ? null : _useClassic,
          child: const Text('Classic'),
        ),
      ],
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required double step,
    required ValueChanged<int> onChanged,
    String? unit,
  }) {
    return Expanded(
      child: NumberStepper(
        value: value.toDouble(),
        label: label,
        unit: unit,
        step: step,
        min: min,
        max: max,
        compact: true,
        onChanged: (next) => onChanged(next.round()),
      ),
    );
  }

  Widget _actions({
    required bool running,
    required bool finished,
    required WorkoutSessionController? clock,
  }) {
    if (finished) {
      return _wideButton('Again', _stopToReady);
    }
    if (running && clock != null) {
      return _runControls(clock);
    }
    return _wideButton('Start', _start);
  }

  Widget _runControls(WorkoutSessionController clock) {
    final paused = clock.state.isPaused;
    final working = clock.state.phase == SessionPhase.work;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: clock.togglePause,
            icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(paused ? 'Resume' : 'Pause'),
          ),
        ),
        if (working) ...[
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: clock.skipCurrent,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Skip'),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _stopToReady,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop'),
          ),
        ),
      ],
    );
  }

  Widget _wideButton(String label, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
