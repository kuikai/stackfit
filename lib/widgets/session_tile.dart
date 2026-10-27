import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils.dart';
import '../models/models.dart';
import '../providers/completed_sessions_provider.dart';
import 'set_log_list.dart';

/// One finished session: date, duration, and a sets/reps/kg summary.
/// Tapping a session with logged sets opens them in a bottom sheet.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    this.showWorkoutName = true,
  });

  final CompletedSession session;

  /// False on the per-workout history page, where the name is the title.
  final bool showWorkoutName;

  /// "3 sets · 24 reps logged", or with " · 1440 kg total" when weighted.
  static String setSummary(CompletedSession session) {
    final base =
        '${session.setLogs.length} sets · ${session.totalRepsLogged} reps';
    final volume = session.totalVolumeKg;
    if (volume <= 0) {
      return '$base logged';
    }
    return '$base · ${SetLog.formatKg(volume)} kg total';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = AppUtils.formatSessionDate(session.completedAt);
    final mutedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.62),
    );

    final title = showWorkoutName ? session.workoutName : date;
    final subtitleLines = <String>[
      if (showWorkoutName) date,
      if (session.hasSetLogs) setSummary(session),
    ];

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: subtitleLines.isEmpty
            ? null
            : Text(subtitleLines.join('\n'), style: mutedStyle),
        isThreeLine: subtitleLines.length > 1,
        onTap: session.hasSetLogs
            ? () => showSessionSetLogs(context, session)
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              session.formattedDuration,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${session.totalExercises} ex',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with every logged set of [session], grouped by exercise.
/// Swipe one exercise away. The session stays in history.
Future<void> showSessionSetLogs(
  BuildContext context,
  CompletedSession session,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SessionSetLogsSheet(sessionId: session.id),
  );
}

class _SessionSetLogsSheet extends ConsumerWidget {
  const _SessionSetLogsSheet({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = _findSession(ref.watch(completedSessionsProvider));
    _closeWhenLogsAreGone(context, ref);
    if (session == null || !session.hasSetLogs) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.workoutName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppUtils.formatSessionDate(session.completedAt),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SetLogList(
                logs: session.setLogs,
                onDeleteGroup: (group) =>
                    _deleteExerciseLog(ref, session, group),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CompletedSession? _findSession(List<CompletedSession> sessions) {
    for (final session in sessions) {
      if (session.id == sessionId) {
        return session;
      }
    }
    return null;
  }

  void _closeWhenLogsAreGone(BuildContext context, WidgetRef ref) {
    ref.listen(completedSessionsProvider, (previous, next) {
      final current = _findSession(next);
      if (current != null && current.hasSetLogs) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    });
  }
}

void _deleteExerciseLog(
  WidgetRef ref,
  CompletedSession session,
  List<SetLog> group,
) {
  final log = group.first;
  unawaited(
    ref
        .read(completedSessionsProvider.notifier)
        .removeExerciseLog(
          sessionId: session.id,
          exerciseId: log.exerciseId,
          round: log.round,
        ),
  );
}
