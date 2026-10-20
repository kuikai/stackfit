import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../providers/completed_sessions_provider.dart';
import '../../providers/pro_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/session_tile.dart';
import 'history_screen.dart';

/// Past sessions of one workout, with a short "done N times" header.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
  });

  final String workoutId;
  final String workoutName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsForWorkoutProvider(workoutId));
    final isPro = ref.watch(isProProvider);
    final totalCount = ref.watch(completedSessionsProvider).length;

    return Scaffold(
      appBar: AppBar(title: Text(workoutName)),
      body: sessions.isEmpty
          ? const EmptyState(
              title: 'Not done yet',
              message: 'Finish this workout once and it will show up here.',
              icon: Icons.history_rounded,
            )
          : Column(
              children: [
                if (!isPro && totalCount > AppConstants.freeHistoryLimit)
                  const FreeHistoryBanner(),
                Expanded(
                  child: ListView.separated(
                    padding: context.pageGutter(top: 8, bottom: 24),
                    itemCount: sessions.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _WorkoutStats(sessions: sessions);
                      }
                      return SessionTile(
                        session: sessions[index - 1],
                        showWorkoutName: false,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Times done, last date, and best volume (when weights were logged).
class _WorkoutStats extends StatelessWidget {
  const _WorkoutStats({required this.sessions});

  final List<CompletedSession> sessions;

  @override
  Widget build(BuildContext context) {
    final count = sessions.length;
    final last = sessions.first;
    var bestVolume = 0.0;
    for (final session in sessions) {
      if (session.totalVolumeKg > bestVolume) {
        bestVolume = session.totalVolumeKg;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: _Stat(label: 'Done', value: '$count×'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Stat(
              label: 'Last',
              value: AppUtils.formatSessionDate(last.completedAt),
            ),
          ),
          if (bestVolume > 0) ...[
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(
                label: 'Best volume',
                value: '${SetLog.formatKg(bestVolume)} kg',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
