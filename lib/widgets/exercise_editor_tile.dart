import 'package:flutter/material.dart';

import '../models/models.dart';

/// Row used inside the workout editor exercise list.
class ExerciseEditorTile extends StatelessWidget {
  const ExerciseEditorTile({
    super.key,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  final Exercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            EditorMoveButton(
              tooltip: 'Move up',
              icon: Icons.keyboard_arrow_up_rounded,
              onPressed: onMoveUp,
            ),
            EditorMoveButton(
              tooltip: 'Move down',
              icon: Icons.keyboard_arrow_down_rounded,
              onPressed: onMoveDown,
            ),
          ],
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

/// Small up or down control used on exercise rows and circuit headers.
class EditorMoveButton extends StatelessWidget {
  const EditorMoveButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 28,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}
