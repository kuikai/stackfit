import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';

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
    this.embedded = false,
  });

  final Workout workout;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onHistory;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveToSection;

  /// True when this row sits inside a section card (no extra Card chrome).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final look = context.skinLook;
    final exerciseCount = workout.exercises.length;
    final durationLabel = AppUtils.formatDurationFriendly(
      workout.estimatedDurationSeconds,
    );

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
                    '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}'
                    ' · ~$durationLabel',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
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
      return row;
    }
    return Card(
      margin: EdgeInsets.only(bottom: look.listGap),
      child: row,
    );
  }
}

enum _WorkoutMenuAction { edit, history, move, duplicate, delete }
