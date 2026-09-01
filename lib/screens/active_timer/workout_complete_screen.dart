import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/models.dart';
import '../../providers/completed_sessions_provider.dart';
import '../../services/sound_service.dart';

class WorkoutCompleteArgs {
  const WorkoutCompleteArgs({
    required this.workout,
    required this.durationSeconds,
  });

  final Workout workout;
  final int durationSeconds;
}

class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  const WorkoutCompleteScreen({
    super.key,
    required this.args,
  });

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
    await ref.read(completedSessionsProvider.notifier).addSession(
          CompletedSession(
            id: AppUtils.newId(),
            workoutId: workout.id,
            workoutName: workout.name,
            completedAt: DateTime.now(),
            durationSeconds: widget.args.durationSeconds,
            totalExercises: workout.exercises.length,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args = widget.args;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
