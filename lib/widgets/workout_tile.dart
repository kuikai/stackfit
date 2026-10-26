import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import 'skin_panel.dart';

/// A single workout row on the Home screen.
class WorkoutTile extends StatelessWidget {
  const WorkoutTile({
    super.key,
    required this.workout,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    required this.onHistory,
    this.onDuplicate,
    this.onMoveToSection,
    this.onStartOver,
    this.inProgress = false,
    this.embedded = false,
  });

  final Workout workout;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onHistory;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveToSection;

  /// Clears a saved run and starts from the first exercise.
  final VoidCallback? onStartOver;

  /// True when this workout has a saved place to continue.
  final bool inProgress;

  /// True when this row sits inside a section card (no extra Card chrome).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final look = context.skinLook;
    final exerciseCount = workout.exercises.length;
    final circuitCount = workout.circuitCount;
    final durationLabel = AppUtils.formatDurationFriendly(
      workout.estimatedDurationSeconds,
    );
    final circuitLabel = circuitCount == 0
        ? ''
        : ' · $circuitCount circuit${circuitCount == 1 ? '' : 's'}';
    final detail =
        '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}'
        '$circuitLabel'
        ' · ~$durationLabel';

    final row = InkWell(
      borderRadius: look.cornerRadius,
      onTap: onStart,
      child: Padding(
        padding: EdgeInsets.fromLTRB(embedded ? 8 : 16, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: look.cornerRadiusSmall,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inProgress ? 'In progress · $detail' : detail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<_WorkoutMenuAction>(
              tooltip: 'Workout options',
              onSelected: (action) {
                switch (action) {
                  case _WorkoutMenuAction.edit:
                    onEdit();
                  case _WorkoutMenuAction.history:
                    onHistory();
                  case _WorkoutMenuAction.startOver:
                    onStartOver?.call();
                  case _WorkoutMenuAction.move:
                    onMoveToSection?.call();
                  case _WorkoutMenuAction.duplicate:
                    onDuplicate?.call();
                  case _WorkoutMenuAction.delete:
                    onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _WorkoutMenuAction.edit,
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: _WorkoutMenuAction.history,
                  child: Text('History'),
                ),
                if (onStartOver != null)
                  const PopupMenuItem(
                    value: _WorkoutMenuAction.startOver,
                    child: Text('Start over'),
                  ),
                if (onMoveToSection != null)
                  const PopupMenuItem(
                    value: _WorkoutMenuAction.move,
                    child: Text('Move to section'),
                  ),
                if (onDuplicate != null)
                  const PopupMenuItem(
                    value: _WorkoutMenuAction.duplicate,
                    child: Text('Duplicate'),
                  ),
                const PopupMenuItem(
                  value: _WorkoutMenuAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: SkinPanel(overPortrait: true, child: row),
      );
    }
    return SkinPanel(
      margin: EdgeInsets.only(bottom: look.listGap),
      overPortrait: true,
      child: row,
    );
  }
}

enum _WorkoutMenuAction { edit, history, startOver, move, duplicate, delete }
