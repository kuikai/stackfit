import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import 'fit_menu_button.dart';
import 'home_reorder.dart';
import 'skin_panel.dart';
import 'workout_tile.dart';

/// A named folder on Home, with its days listed like a Bro Split plan.
class WorkoutSectionCard extends StatefulWidget {
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
    this.dragHandle,
    this.dragIndex,
    this.onReorderWorkouts,
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

  /// Grip on the section header. Finger down here drags the whole folder.
  final Widget? dragHandle;

  /// Home-list index so a long-press on the header can start the same drag.
  final int? dragIndex;

  final void Function(int from, int to)? onReorderWorkouts;

  @override
  State<WorkoutSectionCard> createState() => _WorkoutSectionCardState();
}

class _WorkoutSectionCardState extends State<WorkoutSectionCard> {
  bool _open = true;

  VoidCallback? _startOverFor(Workout workout) {
    if (widget.onStartOver == null ||
        !(widget.isInProgress?.call(workout) ?? false)) {
      return null;
    }
    return () => widget.onStartOver!(workout);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final count = widget.workouts.length;
    var seconds = 0;
    for (final workout in widget.workouts) {
      seconds += workout.estimatedDurationSeconds;
    }
    final duration = AppUtils.formatDurationFriendly(
      count == 0 ? 0 : seconds ~/ count,
    );

    final look = context.skinLook;
    Widget header = ListTile(
      onTap: () => setState(() => _open = !_open),
      contentPadding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      leading: Icon(
        _open ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
      ),
      title: Text(
        widget.section,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        '$count session${count == 1 ? '' : 's'} · ~$duration each',
        style: theme.textTheme.bodySmall?.copyWith(color: muted),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.dragHandle != null) widget.dragHandle!,
          FitMenuButton<_SectionMenuAction>(
            tooltip: 'Section options',
            onSelected: (action) {
              switch (action) {
                case _SectionMenuAction.add:
                  widget.onAddWorkout();
                case _SectionMenuAction.rename:
                  widget.onRename();
                case _SectionMenuAction.dissolve:
                  widget.onDissolve();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _SectionMenuAction.add,
                child: Text('Add workout'),
              ),
              const PopupMenuItem(
                value: _SectionMenuAction.rename,
                child: Text('Rename section'),
              ),
              const PopupMenuItem(
                value: _SectionMenuAction.dissolve,
                child: Text('Ungroup'),
              ),
            ],
          ),
        ],
      ),
    );
    final dragIndex = widget.dragIndex;
    if (dragIndex != null) {
      header = ReorderableDelayedDragStartListener(
        index: dragIndex,
        child: header,
      );
    }

    return SkinPanel(
      margin: EdgeInsets.only(bottom: look.listGap),
      overPortrait: true,
      child: Column(children: [header, if (_open) _workoutList()]),
    );
  }

  Widget _workoutList() {
    final workouts = widget.workouts;
    if (workouts.length < 2 || widget.onReorderWorkouts == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          children: [
            for (var i = 0; i < workouts.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _tile(workouts[i], i),
            ],
          ],
        ),
      );
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: workouts.length,
      proxyDecorator: homeReorderProxy,
      onReorderItem: widget.onReorderWorkouts!,
      itemBuilder: (context, index) {
        return ReorderableDelayedDragStartListener(
          key: ValueKey(workouts[index].id),
          index: index,
          child: _tile(workouts[index], index),
        );
      },
    );
  }

  Widget _tile(Workout workout, int index) {
    return WorkoutTile(
      workout: workout,
      embedded: true,
      inProgress: widget.isInProgress?.call(workout) ?? false,
      dragHandle:
          widget.onReorderWorkouts != null && widget.workouts.length >= 2
          ? homeDragHandle(index)
          : null,
      onStart: () => widget.onStart(workout),
      onEdit: () => widget.onEdit(workout),
      onHistory: () => widget.onHistory(workout),
      onDelete: () => widget.onDelete(workout),
      onMoveToSection: () => widget.onMoveToSection(workout),
      onDuplicate: widget.onDuplicate == null
          ? null
          : () => widget.onDuplicate!(workout),
      onStartOver: _startOverFor(workout),
    );
  }
}

enum _SectionMenuAction { add, rename, dissolve }
