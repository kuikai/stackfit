import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/completed_sessions_provider.dart';
import '../../providers/pro_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/session_tile.dart';

/// Every finished session across all workouts, newest first.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(visibleCompletedSessionsProvider);
    final isPro = ref.watch(isProProvider);
    final totalCount = ref.watch(completedSessionsProvider).length;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
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
                  child: ListView.separated(
                    padding: context.pageGutter(top: 8, bottom: 24),
                    itemCount: sessions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return SessionTile(session: sessions[index]);
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
