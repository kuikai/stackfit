import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/workouts_provider.dart';
import '../active_timer/active_timer_screen.dart';
import '../history/workout_history_screen.dart';
import '../plans/plan_library_screen.dart';
import '../workout_editor/workout_editor_screen.dart';
import 'section_dialogs.dart';

Future<void> startHomeWorkout(BuildContext context, Workout workout) async {
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

Future<void> openHomePlans(BuildContext context) async {
  await Navigator.of(
    context,
  ).push<void>(MaterialPageRoute(builder: (_) => const PlanLibraryScreen()));
}

Future<void> openHomeWorkoutHistory(
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

Future<void> showHomeCreateOptions(
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
                createHomeWorkout(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('New section'),
              subtitle: const Text('Group days, like Bro Split'),
              onTap: () {
                Navigator.pop(sheetContext);
                createHomeSection(context, ref, workouts);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> createHomeWorkout(
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

  await openHomeEditor(context, section: section);
}

Future<void> openHomeEditor(
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

Future<void> deleteHomeWorkout(
  BuildContext context,
  WidgetRef ref,
  Workout workout,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete workout?'),
        content: Text('"${workout.name}" will be removed.'),
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

Future<void> duplicateHomeWorkout(
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
      const SnackBar(content: Text('Cannot duplicate. Workout limit reached.')),
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
  ).showSnackBar(SnackBar(content: Text('Duplicated as "${copy.name}"')));
}

Future<void> moveHomeWorkout(
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
  await ref.read(workoutsProvider.notifier).moveToSection(workout.id, section);
}

Future<void> renameHomeSection(
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

Future<void> dissolveHomeSection(
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
          '"$section" will be removed. The workouts stay on Home on their own.',
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

Future<void> createHomeSection(
  BuildContext context,
  WidgetRef ref,
  List<Workout> workouts,
) async {
  final name = await promptSectionName(context);
  if (name == null || !context.mounted) {
    return;
  }

  final ungrouped = workouts
      .where((workout) => workout.section == null)
      .toList();
  if (ungrouped.isEmpty) {
    await createHomeWorkout(context, ref, section: name);
    return;
  }

  final selected = await showDialog<List<Workout>>(
    context: context,
    builder: (context) =>
        PickWorkoutsDialog(title: 'Add to "$name"', workouts: ungrouped),
  );
  if (!context.mounted) {
    return;
  }
  if (selected == null || selected.isEmpty) {
    await createHomeWorkout(context, ref, section: name);
    return;
  }
  final notifier = ref.read(workoutsProvider.notifier);
  for (final workout in selected) {
    await notifier.moveToSection(workout.id, name);
  }
}
