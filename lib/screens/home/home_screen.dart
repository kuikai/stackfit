import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/pro_provider.dart';
import '../../providers/workouts_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/workout_limit_banner.dart';
import '../../widgets/workout_tile.dart';
import '../active_timer/active_timer_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import '../workout_editor/workout_editor_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onCreateWorkout(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Workout'),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: WorkoutLimitBanner(),
          ),
          Expanded(
            child: workouts.isEmpty
                ? EmptyState(
                    title: 'No workouts yet',
                    message:
                        'Create a custom workout with timer and set-based exercises.',
                    action: FilledButton.icon(
                      onPressed: () => _onCreateWorkout(context, ref),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create Workout'),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      return WorkoutTile(
                        workout: workout,
                        onStart: () => _onStartWorkout(context, workout),
                        onEdit: () =>
                            _openEditor(context, workoutId: workout.id),
                        onDelete: () => _onDeleteWorkout(context, ref, workout),
                        onDuplicate: isPro
                            ? () => _onDuplicateWorkout(context, ref, workout)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStartWorkout(BuildContext context, Workout workout) async {
    if (workout.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one exercise before starting.'),
        ),
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ActiveTimerScreen(workout: workout),
      ),
    );
  }

  Future<void> _onCreateWorkout(BuildContext context, WidgetRef ref) async {
    final canCreate = ref.read(canCreateWorkoutProvider);
    if (!canCreate) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Free limit is 3 workouts. Unlock Pro for unlimited.',
          ),
        ),
      );
      return;
    }

    await _openEditor(context);
  }

  Future<void> _openEditor(
    BuildContext context, {
    String? workoutId,
  }) async {
    await Navigator.of(context).push<Workout>(
      MaterialPageRoute(
        builder: (_) => WorkoutEditorScreen(workoutId: workoutId),
      ),
    );
  }

  Future<void> _onDeleteWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete workout?'),
          content: Text('“${workout.name}” will be removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(workoutsProvider.notifier).deleteWorkout(workout.id);
  }

  Future<void> _onDuplicateWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final canCreate = ref.read(canCreateWorkoutProvider);
    if (!canCreate) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot duplicate — workout limit reached.'),
        ),
      );
      return;
    }

    final copy =
        await ref.read(workoutsProvider.notifier).duplicateWorkout(workout.id);
    if (copy == null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicated as “${copy.name}”')),
    );
  }
}
