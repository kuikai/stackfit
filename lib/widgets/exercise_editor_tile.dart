import 'package:flutter/material.dart';

import '../models/models.dart';

/// Row used inside the workout editor exercise list.
class ExerciseEditorTile extends StatelessWidget {
  const ExerciseEditorTile({
    super.key,
    required this.exercise,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  final Exercise exercise;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        leading: ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.drag_handle_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        title: Text(
          exercise.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          _exerciseDetail(exercise),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Remove',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  String _exerciseDetail(Exercise exercise) {
    if (exercise.type == ExerciseType.timer) {
      final rounds = exercise.sets ?? 1;
      final roundsText = rounds > 1 ? ' · $rounds sets' : '';
      return '${exercise.workSeconds}s work · ${exercise.restSeconds}s rest$roundsText';
    }
    final repsText = exercise.reps != null ? ' × ${exercise.reps}' : '';
    return '${exercise.sets} sets$repsText · ${exercise.restSeconds}s rest';
  }
}