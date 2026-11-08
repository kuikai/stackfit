import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/completed_sessions_provider.dart';
import '../../providers/pro_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/history_workout_section.dart';

/// Finished sessions grouped by workout, newest workout first.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(visibleCompletedSessionsProvider);
    final groups = groupSessionsByWorkout(sessions);
    final isPro = ref.watch(isProProvider);
    final totalCount = ref.watch(completedSessionsProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (totalCount > 0)
            TextButton(
              onPressed: () => unawaited(_confirmClearHistory(context, ref)),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: sessions.isEmpty
          ? const EmptyState(
              title: 'No sessions yet',
              message: 'Finished workouts will show up here.',
              icon: Icons.history_rounded,
            )
          : Column(
              children: [
                if (!isPro && totalCount > AppConstants.freeHistoryLimit)
                  const FreeHistoryBanner(),
                Expanded(
                  child: ListView.builder(
                    padding: context.pageGutter(top: 8, bottom: 24),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      return HistoryWorkoutSection(group: groups[index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Tells free users that only the last N sessions are shown.
class FreeHistoryBanner extends StatelessWidget {
  const FreeHistoryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: context.pageGutter(bottom: 8),
      child: Material(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'Showing last ${AppConstants.freeHistoryLimit} sessions. '
            'Unlock Pro for full history.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete all history?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      );
    },
  );
  if (confirmed != true) {
    return;
  }
  await ref.read(completedSessionsProvider.notifier).clearAll();
}
