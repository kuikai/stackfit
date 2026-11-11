import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import 'fit_menu_button.dart';
import 'folder_shell.dart';

/// Folder header on Home. Open days continue the same shell as separate rows.
class WorkoutSectionCard extends StatelessWidget {
  const WorkoutSectionCard({
    super.key,
    required this.section,
    required this.workouts,
    required this.open,
    required this.onToggleOpen,
    required this.onRename,
    required this.onDissolve,
    required this.onAddWorkout,
    this.dragIndex,
    this.onMoveUp,
    this.onMoveDown,
  });

  final String section;
  final List<Workout> workouts;
  final bool open;
  final VoidCallback onToggleOpen;
  final VoidCallback onRename;
  final VoidCallback onDissolve;
  final VoidCallback onAddWorkout;

  /// Home-list index so a long-press can drag a closed folder among Home rows.
  final int? dragIndex;

  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final count = workouts.length;
    var seconds = 0;
    for (final workout in workouts) {
      seconds += workout.estimatedDurationSeconds;
    }
    final average = count == 0 ? 0 : seconds ~/ count;
    final duration = AppUtils.formatDurationFriendly(average);
    final look = context.skinLook;

    Widget header = ListTile(
      onTap: onToggleOpen,
      contentPadding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
      leading: Icon(
        open ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
      ),
      title: Text(
        section,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        average <= 0
            ? '$count session${count == 1 ? '' : 's'}'
            : '$count session${count == 1 ? '' : 's'} · ~$duration each',
        style: theme.textTheme.bodySmall?.copyWith(color: muted),
      ),
      trailing: FitMenuButton<_SectionMenuAction>(
        tooltip: 'Section options',
        onSelected: (action) {
          switch (action) {
            case _SectionMenuAction.add:
              onAddWorkout();
            case _SectionMenuAction.moveUp:
              onMoveUp?.call();
            case _SectionMenuAction.moveDown:
              onMoveDown?.call();
            case _SectionMenuAction.rename:
              onRename();
            case _SectionMenuAction.dissolve:
              onDissolve();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: _SectionMenuAction.add,
            child: Text('Add workout'),
          ),
          if (onMoveUp != null)
            const PopupMenuItem(
              value: _SectionMenuAction.moveUp,
              child: Text('Move up'),
            ),
          if (onMoveDown != null)
            const PopupMenuItem(
              value: _SectionMenuAction.moveDown,
              child: Text('Move down'),
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
    );

    final dragIndex = this.dragIndex;
    if (dragIndex != null) {
      header = ReorderableDelayedDragStartListener(
        index: dragIndex,
        child: header,
      );
    }

    return FolderShell(
      role: open ? FolderShellRole.header : FolderShellRole.alone,
      margin: EdgeInsets.only(bottom: open ? 0 : look.listGap),
      child: header,
    );
  }
}

enum _SectionMenuAction { add, moveUp, moveDown, rename, dissolve }
