import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/in_progress_provider.dart';
import '../../providers/pro_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workouts_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/plan_library_tile.dart';
import '../../widgets/skin_artwork.dart';
import '../../widgets/skin_panel.dart';
import '../../widgets/workout_limit_banner.dart';
import '../../widgets/workout_section_card.dart';
import '../../widgets/workout_tile.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'home_actions.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider);
    final isPro = ref.watch(isProProvider);
    final runs = ref.watch(inProgressProvider);
    final groups = groupWorkoutsForHome(workouts);
    final looseRuns = _runsNotOnHome(runs, workouts);
    final background = ref.watch(settingsProvider).skin.homePlateAsset;

    return Scaffold(
      extendBodyBehindAppBar: background != null,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: background != null ? Colors.transparent : null,
        surfaceTintColor: background != null ? Colors.transparent : null,
        actions: [
          IconButton(
            tooltip: 'Plans',
            onPressed: () => openHomePlans(context),
            icon: const Icon(Icons.auto_awesome_motion_outlined),
          ),
          IconButton(
            tooltip: 'History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showHomeCreateOptions(context, ref, workouts),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (background != null) ...[
            Image.asset(
              background,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            // Quiet the picture so the workout holders read as a layer on top.
            const ColoredBox(color: Color(0x6605060F)),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 20),
              child: SkinMascot(size: 112, alignment: Alignment.bottomLeft),
            ),
          ],
          SafeArea(
            top: background != null,
            bottom: false,
            child: Column(
              children: [
                const SkinArtworkBanner(),
                Padding(
                  padding: context.pageGutter(bottom: 8),
                  child: const WorkoutLimitBanner(),
                ),
                Expanded(
                  child: workouts.isEmpty && looseRuns.isEmpty
                      ? _emptyHome(context, ref)
                      : ListView.builder(
                          padding: context.pageGutter(top: 8, bottom: 100),
                          itemCount: _homeItemCount(
                            looseRuns,
                            workouts,
                            groups,
                          ),
                          itemBuilder: (context, index) {
                            return _homeItem(
                              context,
                              ref,
                              index: index,
                              looseRuns: looseRuns,
                              groups: groups,
                              runs: runs,
                              isPro: isPro,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHome(BuildContext context, WidgetRef ref) {
    return EmptyState(
      title: 'No workouts yet',
      message:
          'Create a custom workout with timer and set-based exercises, '
          'or start from a ready-made plan.',
      action: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () => createHomeWorkout(context, ref),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Workout'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => openHomePlans(context),
            icon: const Icon(Icons.auto_awesome_motion_outlined),
            label: const Text('Browse plans'),
          ),
        ],
      ),
    );
  }

  Widget _homeItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required List<InProgressWorkout> looseRuns,
    required List<WorkoutHomeGroup> groups,
    required List<InProgressWorkout> runs,
    required bool isPro,
  }) {
    if (index < looseRuns.length) {
      final run = looseRuns[index];
      return _ContinueRunRow(
        run: run,
        onContinue: () => openInProgressRun(context, ref, run),
        onStartOver: () => openInProgressRun(context, ref, run, fresh: true),
      );
    }
    final rest = index - looseRuns.length;
    if (groups.isEmpty) {
      return _emptyHome(context, ref);
    }
    if (rest == 0) {
      return PlanLibraryTile(onTap: () => openHomePlans(context));
    }
    return _buildGroup(
      context,
      ref,
      groups[rest - 1],
      runs: runs,
      isPro: isPro,
    );
  }

  Widget _buildGroup(
    BuildContext context,
    WidgetRef ref,
    WorkoutHomeGroup group, {
    required List<InProgressWorkout> runs,
    required bool isPro,
  }) {
    if (!group.isSection) {
      final workout = group.workouts.single;
      final inProgress = _matchesRun(runs, workout);
      return WorkoutTile(
        workout: workout,
        inProgress: inProgress,
        onStart: () => startHomeWorkout(context, ref, workout),
        onStartOver: inProgress
            ? () => startHomeWorkout(context, ref, workout, fresh: true)
            : null,
        onEdit: () => openHomeEditor(context, workoutId: workout.id),
        onHistory: () => openHomeWorkoutHistory(context, workout),
        onDelete: () => deleteHomeWorkout(context, ref, workout),
        onMoveToSection: () => moveHomeWorkout(context, ref, workout),
        onDuplicate: isPro
            ? () => duplicateHomeWorkout(context, ref, workout)
            : null,
      );
    }

    return WorkoutSectionCard(
      section: group.section!,
      workouts: group.workouts,
      onStart: (workout) => startHomeWorkout(context, ref, workout),
      onStartOver: (workout) =>
          startHomeWorkout(context, ref, workout, fresh: true),
      isInProgress: (workout) => _matchesRun(runs, workout),
      onEdit: (workout) => openHomeEditor(context, workoutId: workout.id),
      onHistory: (workout) => openHomeWorkoutHistory(context, workout),
      onDelete: (workout) => deleteHomeWorkout(context, ref, workout),
      onMoveToSection: (workout) => moveHomeWorkout(context, ref, workout),
      onRename: () => renameHomeSection(context, ref, group.section!),
      onDissolve: () => dissolveHomeSection(context, ref, group.section!),
      onAddWorkout: () =>
          createHomeWorkout(context, ref, section: group.section),
      onDuplicate: isPro
          ? (workout) => duplicateHomeWorkout(context, ref, workout)
          : null,
    );
  }
}

int _homeItemCount(
  List<InProgressWorkout> looseRuns,
  List<Workout> workouts,
  List<WorkoutHomeGroup> groups,
) {
  if (workouts.isEmpty) {
    return looseRuns.length + 1;
  }
  return looseRuns.length + 1 + groups.length;
}

bool _matchesRun(List<InProgressWorkout> runs, Workout workout) {
  for (final run in runs) {
    if (run.workout.id == workout.id &&
        run.canResume &&
        run.matchesLayout(workout)) {
      return true;
    }
  }
  return false;
}

List<InProgressWorkout> _runsNotOnHome(
  List<InProgressWorkout> runs,
  List<Workout> workouts,
) {
  final ids = {for (final workout in workouts) workout.id};
  return [
    for (final run in runs)
      if (run.canResume && !ids.contains(run.workout.id)) run,
  ];
}

/// A plan day left unfinished, shown because it is not in the workout list.
class _ContinueRunRow extends StatelessWidget {
  const _ContinueRunRow({
    required this.run,
    required this.onContinue,
    required this.onStartOver,
  });

  final InProgressWorkout run;
  final VoidCallback onContinue;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final look = context.skinLook;
    return SkinPanel(
      margin: EdgeInsets.only(bottom: look.listGap),
      overPortrait: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              run.workout.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'In progress',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onContinue,
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onStartOver,
                    child: const Text('Start over'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
