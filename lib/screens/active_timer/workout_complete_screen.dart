import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/models.dart';
import '../../providers/completed_sessions_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/chibi_run.dart';
import '../../widgets/set_log_list.dart';
import '../home/home_screen.dart';

class WorkoutCompleteArgs {
  const WorkoutCompleteArgs({
    required this.workout,
    required this.durationSeconds,
    this.setLogs = const [],
  });

  final Workout workout;
  final int durationSeconds;
  final List<SetLog> setLogs;
}

class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  const WorkoutCompleteScreen({super.key, required this.args});

  final WorkoutCompleteArgs args;

  @override
  ConsumerState<WorkoutCompleteScreen> createState() =>
      _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends ConsumerState<WorkoutCompleteScreen> {
  final _sound = SoundService();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _persistSession());
    _sound.playComplete();
  }

  Future<void> _persistSession() async {
    if (_saved) {
      return;
    }
    _saved = true;
    final workout = widget.args.workout;
    await ref
        .read(completedSessionsProvider.notifier)
        .addSession(
          CompletedSession(
            id: AppUtils.newId(),
            workoutId: workout.id,
            workoutName: workout.name,
            completedAt: DateTime.now(),
            durationSeconds: widget.args.durationSeconds,
            totalExercises: workout.exercises.length,
            setLogs: widget.args.setLogs,
          ),
        );
  }

  /// Back to the first screen (Home). Circuit or plain sets does not matter.
  void _goHome() {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    // Finish page somehow became the only route — rebuild Home so Done
    // never leaves the user stuck on this screen.
    navigator.pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runFrames = ref.watch(settingsProvider).skin.mascotRunFrames;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _finishColumn(runFrames),
        ),
      ),
    );
  }

  Widget _finishColumn(List<String> runFrames) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args = widget.args;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Workout complete',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  args.workout.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Text(
                  AppUtils.formatDurationFriendly(args.durationSeconds),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${args.workout.exercises.length} exercises',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (args.setLogs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SetLogList(logs: args.setLogs, scrollable: false),
                ],
                _finishLane(runFrames),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _goHome,
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _finishLane(List<String> frames) {
    if (frames.isEmpty) {
      return const SizedBox(height: 24);
    }
    return IgnorePointer(
      child: SizedBox(
        height: 120,
        width: double.infinity,
        child: ChibiRun(frames: frames),
      ),
    );
  }
}
