import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../providers/pro_provider.dart';
import '../../providers/workouts_provider.dart';
import '../../services/plan_workout_builder.dart';
import '../../widgets/empty_state.dart';
import '../active_timer/active_timer_screen.dart';

/// Shows every day of a plan. Start and Add are Pro features.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({super.key, required this.planId});

  final String planId;

  static const String proMessage =
      'Plans are a Pro feature. Unlock Pro in Settings.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = PlanLibrary.byId(planId);
    if (plan == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          title: 'Plan not found',
          message: 'This plan is no longer available.',
        ),
      );
    }

    final isPro = ref.watch(isProProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: ListView(
        padding: context.pageGutter(top: 8, bottom: 24),
        children: [
          _PlanSummary(plan: plan),
          const SizedBox(height: 20),
          Text(
            plan.isSingleDay ? 'Session' : 'Sessions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final day in plan.days)
            _PlanDayTile(
              day: day,
              isPro: isPro,
              initiallyExpanded: plan.isSingleDay,
              onStart: () => _onStart(context, ref, plan, day),
              onAdd: () => _onAddDay(context, ref, plan, day),
            ),
        ],
      ),
      bottomNavigationBar: plan.isSingleDay
          ? null
          : SafeArea(
              child: Padding(
                padding: context.pageGutter(top: 8, bottom: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => _onAddToWorkouts(context, ref, plan),
                    icon: Icon(
                      isPro
                          ? Icons.playlist_add_rounded
                          : Icons.lock_outline_rounded,
                    ),
                    label: Text(
                      'Add all ${plan.days.length} sessions to My workouts',
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _onAddDay(
    BuildContext context,
    WidgetRef ref,
    WorkoutPlan plan,
    PlanDay day,
  ) async {
    if (!_requirePro(context, ref)) {
      return;
    }
    final workout = PlanWorkoutBuilder.buildWorkoutFromPlanDay(plan, day);
    await ref.read(workoutsProvider.notifier).addWorkout(workout);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added “${workout.name}” to My workouts')),
    );
  }

  bool _requirePro(BuildContext context, WidgetRef ref) {
    if (ref.read(isProProvider)) {
      return true;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(proMessage)));
    return false;
  }

  Future<void> _onStart(
    BuildContext context,
    WidgetRef ref,
    WorkoutPlan plan,
    PlanDay day,
  ) async {
    if (!_requirePro(context, ref)) {
      return;
    }
    final workout = PlanWorkoutBuilder.buildWorkoutFromPlanDay(plan, day);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ActiveTimerScreen(workout: workout)),
    );
  }

  Future<void> _onAddToWorkouts(
    BuildContext context,
    WidgetRef ref,
    WorkoutPlan plan,
  ) async {
    if (!_requirePro(context, ref)) {
      return;
    }
    final workouts = PlanWorkoutBuilder.buildWorkoutsFromPlan(plan);
    await ref.read(workoutsProvider.notifier).addWorkouts(workouts);
    if (!context.mounted) {
      return;
    }
    final count = workouts.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 1
              ? 'Added “${plan.name}” to My workouts'
              : 'Added “${plan.name}” with $count sessions',
        ),
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final WorkoutPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.62);
    final dayCount = plan.days.length;
    final sessions = dayCount == 1 ? '1 session' : '$dayCount sessions';
    final perSession = AppUtils.formatDurationFriendly(
      plan.averageDayDurationSeconds,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${plan.category} · ${plan.level} · $sessions · ~$perSession each',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          plan.description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.fitness_center_outlined, size: 18, color: muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                plan.equipment,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlanDayTile extends StatelessWidget {
  const _PlanDayTile({
    required this.day,
    required this.isPro,
    required this.initiallyExpanded,
    required this.onStart,
    required this.onAdd,
  });

  final PlanDay day;
  final bool isPro;
  final bool initiallyExpanded;
  final VoidCallback onStart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final count = day.exercises.length;
    final duration = AppUtils.formatDurationFriendly(
      day.estimatedDurationSeconds,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          day.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '$count exercise${count == 1 ? '' : 's'} · ~$duration',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final exercise in day.exercises)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  exercise.toString(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: Icon(
                    isPro
                        ? Icons.play_arrow_rounded
                        : Icons.lock_outline_rounded,
                  ),
                  label: Text('Start ${day.name}'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: Icon(
                    isPro
                        ? Icons.playlist_add_rounded
                        : Icons.lock_outline_rounded,
                  ),
                  label: const Text('Add to My workouts'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
