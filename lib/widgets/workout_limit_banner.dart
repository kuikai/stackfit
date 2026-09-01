import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/pro_provider.dart';
import '../providers/workouts_provider.dart';

/// Shows free-tier workout usage. Hidden for Pro users.
class WorkoutLimitBanner extends ConsumerWidget {
  const WorkoutLimitBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    if (isPro) {
      return const SizedBox.shrink();
    }

    final count = ref.watch(workoutsProvider).length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final atLimit = count >= AppConstants.freeWorkoutLimit;

    return Material(
      color: atLimit
          ? colorScheme.errorContainer.withValues(alpha: 0.65)
          : colorScheme.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                atLimit ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                color: atLimit ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  atLimit
                      ? 'Free limit reached (${AppConstants.freeWorkoutLimit} workouts). Unlock Pro for unlimited.'
                      : '$count of ${AppConstants.freeWorkoutLimit} free workouts',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
