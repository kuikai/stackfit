import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/pro_provider.dart';
import '../../providers/workouts_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/plan_library_tile.dart';
import '../../widgets/skin_artwork.dart';
import '../../widgets/workout_limit_banner.dart';
import '../../widgets/workout_section_card.dart';
import '../../widgets/workout_tile.dart';
import '../active_timer/active_timer_screen.dart';
import '../history/history_screen.dart';
import '../history/workout_history_screen.dart';
import '../plans/plan_library_screen.dart';
import '../settings/settings_screen.dart';
import '../workout_editor/workout_editor_screen.dart';
import 'section_dialogs.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider);
    final isPro = ref.watch(isProProvider);
    final groups = groupWorkoutsForHome(workouts);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Plans',
            onPressed: () => _openPlans(context),
            icon: const Icon(Icons.auto_awesome_motion_outlined),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateOptions(context, ref, workouts),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: Column(
        children: [
          const SkinArtworkBanner(),
          Padding(
            padding: context.pageGutter(bottom: 8),
            child: const WorkoutLimitBanner(),
          ),
          Expanded(
            child: workouts.isEmpty
                ? EmptyState(
                    title: 'No workouts yet',
                    message:
                        'Create a custom workout with timer and set-based exercises, '
                        'or start from a ready-made plan.',
                    action: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _onCreateWorkout(context, ref),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Workout'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openPlans(context),
                          icon: const Icon(Icons.auto_awesome_motion_outlined),
                          label: const Text('Browse plans'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: context.pageGutter(top: 8, bottom: 100),
                    itemCount: groups.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return PlanLibraryTile(
                          onTap: () => _openPlans(context),
                        );
                      }
                      return _buildGroup(
                        context,
                        ref,
                        groups[index - 1],
                        isPro: isPro,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    WidgetRef ref,
    WorkoutHomeGroup group, {
    required bool isPro,
  }) {
    if (!group.isSection) {
      final workout = group.workouts.single;
      return WorkoutTile(
        workout: workout,
        onStart: () => _onStartWorkout(context, workout),
        onEdit: () => _openEditor(context, workoutId: workout.id),
        onHistory: () => _openWorkoutHistory(context, workout),
        onDelete: () => _onDeleteWorkout(context, ref, workout),
        onMoveToSection: () => _onMoveToSection(context, ref, workout),
        onDuplicate: isPro
            ? () => _onDuplicateWorkout(context, ref, workout)
            : null,
      );
    }

    return WorkoutSectionCard(
      section: group.section!,
      workouts: group.workouts,
      onStart: (workout) => _onStartWorkout(context, workout),
      onEdit: (workout) => _openEditor(context, workoutId: workout.id),
      onHistory: (workout) => _openWorkoutHistory(context, workout),
      onDelete: (workout) => _onDeleteWorkout(context, ref, workout),
      onMoveToSection: (workout) => _onMoveToSection(context, ref, workout),
      onRename: () => _onRenameSection(context, ref, group.section!),
      onDissolve: () => _onDissolveSection(context, ref, group.section!),
      onAddWorkout: () =>
          _onCreateWorkout(context, ref, section: group.section),
      onDuplicate: isPro
          ? (workout) => _onDuplicateWorkout(context, ref, workout)
          : null,
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
      MaterialPageRoute(builder: (_) => ActiveTimerScreen(workout: workout)),
    );
  }

  Future<void> _openPlans(BuildContext context) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const PlanLibraryScreen()));
  }

  Future<void> _openWorkoutHistory(
    BuildContext context,
    Workout workout,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WorkoutHistoryScreen(
          workoutId: workout.id,
          workoutName: workout.name,
        ),
      ),
    );
  }

  Future<void> _showCreateOptions(
    BuildContext context,
    WidgetRef ref,
    List<Workout> workouts,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.fitness_center_rounded),
                title: const Text('New workout'),
                subtitle: const Text('A single session'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _onCreateWorkout(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('New section'),
                subtitle: const Text('Group days, like Bro Split'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _onCreateSection(context, ref, workouts);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onCreateWorkout(
    BuildContext context,
    WidgetRef ref, {
    String? section,
  }) async {
    final canCreate = ref.read(canCreateWorkoutProvider);
    if (!canCreate) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Free limit is 3 workouts. Unlock Pro for unlimited.'),
        ),
      );
      return;
    }

    await _openEditor(context, section: section);
  }

  Future<void> _openEditor(
    BuildContext context, {
    String? workoutId,
    String? section,
  }) async {
    await Navigator.of(context).push<Workout>(
      MaterialPageRoute(
        builder: (_) =>
            WorkoutEditorScreen(workoutId: workoutId, initialSection: section),
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
          content: Text('â€œ${workout.name}â€ will be removed.'),
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
          content: Text('Cannot duplicate â€” workout limit reached.'),
        ),
      );
      return;
    }

    final copy = await ref
        .read(workoutsProvider.notifier)
        .duplicateWorkout(workout.id);
    if (copy == null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Duplicated as â€œ${copy.name}â€')));
  }

  Future<void> _onMoveToSection(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final sections = ref.read(workoutsProvider.notifier).sectionNames;
    final choice = await showDialog<String?>(
      context: context,
      builder: (context) =>
          MoveToSectionDialog(current: workout.section, sections: sections),
    );
    if (!context.mounted ||
        choice == null ||
        choice == MoveToSectionDialog.cancelled) {
      return;
    }
    final section = choice == MoveToSectionDialog.none ? null : choice;
    await ref
        .read(workoutsProvider.notifier)
        .moveToSection(workout.id, section);
  }

  Future<void> _onRenameSection(
    BuildContext context,
    WidgetRef ref,
    String section,
  ) async {
    final next = await promptSectionName(context, initial: section);
    if (next == null || !context.mounted) {
      return;
    }
    await ref.read(workoutsProvider.notifier).renameSection(section, next);
  }

  Future<void> _onDissolveSection(
    BuildContext context,
    WidgetRef ref,
    String section,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ungroup section?'),
          content: Text(
            'â€œ$sectionâ€ will be removed. The workouts stay on Home on their own.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Ungroup'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(workoutsProvider.notifier).dissolveSection(section);
  }

  Future<void> _onCreateSection(
    BuildContext context,
    WidgetRef ref,
    List<Workout> workouts,
  ) async {
    final name = await promptSectionName(context);
    if (name == null || !context.mounted) {
      return;
    }

    final ungrouped = workouts.where((w) => w.section == null).toList();
    if (ungrouped.isEmpty) {
      await _onCreateWorkout(context, ref, section: name);
      return;
    }

    final selected = await showDialog<List<Workout>>(
      context: context,
      builder: (context) =>
          PickWorkoutsDialog(title: 'Add to â€œ$nameâ€', workouts: ungrouped),
    );
    if (!context.mounted) {
      return;
    }
    if (selected == null || selected.isEmpty) {
      await _onCreateWorkout(context, ref, section: name);
      return;
    }
    final notifier = ref.read(workoutsProvider.notifier);
    for (final workout in selected) {
      await notifier.moveToSection(workout.id, name);
    }
  }
}
