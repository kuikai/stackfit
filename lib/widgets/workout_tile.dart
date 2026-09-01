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
    this.onDuplicate,
  });

  final Workout workout;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onDuplicate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final exerciseCount = workout.exercises.length;
    final durationLabel = AppUtils.formatDurationFriendly(
      workout.estimatedDurationSeconds,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                      break;
                    case _WorkoutMenuAction.duplicate:
                      onDuplicate?.call();
                      break;
                    case _WorkoutMenuAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _WorkoutMenuAction.edit,
                    child: Text('Edit'),
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
      ),
    );
  }
}

enum _WorkoutMenuAction { edit, duplicate, delete }
