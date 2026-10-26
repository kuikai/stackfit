import 'package:flutter/material.dart';

import '../models/models.dart';

/// Logged sets grouped by exercise, e.g. "Bench Press  8×60 · 8×60 · 6×60"
/// (reps×kg, or just reps for bodyweight sets).
class SetLogList extends StatelessWidget {
  const SetLogList({super.key, required this.logs});

  final List<SetLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groups = groupByExercise(logs);

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final group = groups[index];
          return _SetLogRow(
            title: _groupTitle(group.first),
            summary: SetLog.summarize(group),
            titleStyle: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            summaryStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              height: 1.35,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );
        },
      ),
    );
  }

  static String _groupTitle(SetLog log) {
    if (log.round <= 1) {
      return log.exerciseName;
    }
    return '${log.exerciseName} · round ${log.round}';
  }

  /// Keeps exercise order as performed; one list of sets per exercise.
  static List<List<SetLog>> groupByExercise(List<SetLog> logs) {
    final groups = <List<SetLog>>[];
    for (final log in logs) {
      final previous = groups.isNotEmpty ? groups.last.first : null;
      if (previous != null &&
          previous.exerciseId == log.exerciseId &&
          previous.round == log.round) {
        groups.last.add(log);
      } else {
        groups.add([log]);
      }
    }
    return groups;
  }
}

/// Exercise name, then its sets on the next line. The numbers use the full
/// width of the card, so a long line wraps cleanly instead of breaking
/// beside the name.
class _SetLogRow extends StatelessWidget {
  const _SetLogRow({
    required this.title,
    required this.summary,
    required this.titleStyle,
    required this.summaryStyle,
  });

  final String title;
  final String summary;
  final TextStyle? titleStyle;
  final TextStyle? summaryStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(summary, style: summaryStyle),
        ],
      ),
    );
  }
}
