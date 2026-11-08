import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../widgets/home_reorder.dart';
import '../../widgets/workout_section_card.dart';
import '../../widgets/workout_tile.dart';
import 'continue_run_row.dart';
import 'home_actions.dart';

/// One Home row: a loose workout or a named section.
Widget buildHomeGroup(
  BuildContext context,
  WidgetRef ref,
  WorkoutHomeGroup group, {
  required int groupIndex,
  required List<InProgressWorkout> runs,
  required bool isPro,
}) {
  if (!group.isSection) {
    return _looseWorkoutTile(
      context,
      ref,
      group.workouts.single,
      groupIndex: groupIndex,
      runs: runs,
      isPro: isPro,
    );
  }

  return WorkoutSectionCard(
    section: group.section!,
    workouts: group.workouts,
    dragIndex: groupIndex,
    dragHandle: homeDragHandle(groupIndex),
    onReorderWorkouts: (from, to) =>
        reorderHomeWorkoutInSection(ref, group.workouts[from], to),
    onStart: (workout) => startHomeWorkout(context, ref, workout),
    onStartOver: (workout) =>
        startHomeWorkout(context, ref, workout, fresh: true),
    isInProgress: (workout) => homeRunMatches(runs, workout),
    onEdit: (workout) => openHomeEditor(context, workoutId: workout.id),
    onHistory: (workout) => openHomeWorkoutHistory(context, workout),
    onDelete: (workout) => deleteHomeWorkout(context, ref, workout),
    onMoveToSection: (workout) => moveHomeWorkout(context, ref, workout),
    onRename: () => renameHomeSection(context, ref, group.section!),
    onDissolve: () => dissolveHomeSection(context, ref, group.section!),
    onAddWorkout: () => createHomeWorkout(context, ref, section: group.section),
    onDuplicate: isPro
        ? (workout) => duplicateHomeWorkout(context, ref, workout)
        : null,
  );
}

Widget _looseWorkoutTile(
  BuildContext context,
  WidgetRef ref,
  Workout workout, {
  required int groupIndex,
  required List<InProgressWorkout> runs,
  required bool isPro,
}) {
  final inProgress = homeRunMatches(runs, workout);
  return ReorderableDelayedDragStartListener(
    index: groupIndex,
    child: WorkoutTile(
      workout: workout,
      inProgress: inProgress,
      dragHandle: homeDragHandle(groupIndex),
      onStart: () => startHomeWorkout(context, ref, workout),
      onStartOver: inProgress
          ? () => startHomeWorkout(context, ref, workout, fresh: true)
          : null,
      onEdit: () => openHomeEditor(context, workoutId: workout.id),
      onHistory: () => openHomeWorkoutHistory(context, workout),
      onDelete: () => deleteHomeWorkout(context, ref, workout),
      onMoveToSection: () => moveHomeWorkout(context, ref, workout),
      onDuplicate: isPro
          ? () => duplicateHomeWorkout(context, ref, workout)
          : null,
    ),
  );
}

Widget buildHomeHeader(
  BuildContext context,
  WidgetRef ref, {
  required List<InProgressWorkout> looseRuns,
}) {
  return Column(
    children: [
      for (final run in looseRuns)
        ContinueRunRow(
          run: run,
          onContinue: () => openInProgressRun(context, ref, run),
          onStartOver: () => openInProgressRun(context, ref, run, fresh: true),
        ),
    ],
  );
}

bool homeRunMatches(List<InProgressWorkout> runs, Workout workout) {
  for (final run in runs) {
    if (run.workout.id == workout.id &&
        run.canResume &&
        run.matchesLayout(workout)) {
      return true;
    }
  }
  return false;
}
