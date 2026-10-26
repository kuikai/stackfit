import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import 'skin_panel.dart';
import 'workout_tile.dart';

/// A named folder on Home, with its days listed like a Bro Split plan.
class WorkoutSectionCard extends StatelessWidget {
  const WorkoutSectionCard({
    super.key,
    required this.section,
    required this.workouts,
    required this.onStart,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
    required this.onMoveToSection,
    required this.onRename,
    required this.onDissolve,
    required this.onAddWorkout,
    this.onDuplicate,
    this.onStartOver,
    this.isInProgress,
  });

  final String section;
  final List<Workout> workouts;
  final void Function(Workout workout) onStart;
  final void Function(Workout workout) onEdit;
  final void Function(Workout workout) onHistory;
  final void Function(Workout workout) onDelete;
  final void Function(Workout workout) onMoveToSection;
  final VoidCallback onRename;
  final VoidCallback onDissolve;
  final VoidCallback onAddWorkout;
  final void Function(Workout workout)? onDuplicate;
  final void Function(Workout workout)? onStartOver;
  final bool Function(Workout workout)? isInProgress;

  VoidCallback? _startOverFor(Workout workout) {
    if (onStartOver == null || !(isInProgress?.call(workout) ?? false)) {
      return null;
    }
    return () => onStartOver!(workout);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final count = workouts.length;
    var seconds = 0;
    for (final workout in workouts) {
      seconds += workout.estimatedDurationSeconds;
    }
    final duration = AppUtils.formatDurationFriendly(
      count == 0 ? 0 : seconds ~/ count,
    );

    final look = context.skinLook;
    return SkinPanel(
      margin: EdgeInsets.only(bottom: look.listGap),
      overPortrait: true,
      child: ExpansionTile(
        initiallyExpanded: true,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        tilePadding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        shape: const Border(),
        collapsedShape: const Border(),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          section,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '$count session${count == 1 ? '' : 's'} · ~$duration each',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        trailing: PopupMenuButton<_SectionMenuAction>(
          tooltip: 'Section options',
          onSelected: (action) {
            switch (action) {
              case _SectionMenuAction.add:
                onAddWorkout();
              case _SectionMenuAction.rename:
                onRename();
              case _SectionMenuAction.dissolve:
                onDissolve();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _SectionMenuAction.add,
              child: Text('Add workout'),
            ),
            PopupMenuItem(
              value: _SectionMenuAction.rename,
              child: Text('Rename section'),
            ),
            PopupMenuItem(
              value: _SectionMenuAction.dissolve,
              child: Text('Ungroup'),
            ),
          ],
        ),
        children: [
          for (var i = 0; i < workouts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            WorkoutTile(
              workout: workouts[i],
              embedded: true,
              inProgress: isInProgress?.call(workouts[i]) ?? false,
              onStart: () => onStart(workouts[i]),
              onEdit: () => onEdit(workouts[i]),
              onHistory: () => onHistory(workouts[i]),
              onDelete: () => onDelete(workouts[i]),
              onMoveToSection: () => onMoveToSection(workouts[i]),
              onDuplicate: onDuplicate == null
                  ? null
                  : () => onDuplicate!(workouts[i]),
              onStartOver: _startOverFor(workouts[i]),
            ),
          ],
        ],
      ),
    );
  }
}

enum _SectionMenuAction { add, rename, dissolve }
