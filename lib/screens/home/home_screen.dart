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
import '../../widgets/fit_menu_button.dart';
import '../../widgets/home_reorder.dart';
import '../../widgets/skin_artwork.dart';
import '../../widgets/workout_limit_banner.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';
import 'home_actions.dart';
import 'home_rows.dart';

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
                      : _homeList(
                          context,
                          ref,
                          looseRuns: looseRuns,
                          workouts: workouts,
                          groups: groups,
                          runs: runs,
                          isPro: isPro,
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

  Widget _homeList(
    BuildContext context,
    WidgetRef ref, {
    required List<InProgressWorkout> looseRuns,
    required List<Workout> workouts,
    required List<WorkoutHomeGroup> groups,
    required List<InProgressWorkout> runs,
    required bool isPro,
  }) {
    final padding = context.pageGutter(top: 8, bottom: FitMenuButton.menuRoom);
    final header = buildHomeHeader(
      context,
      ref,
      looseRuns: looseRuns,
      showPlans: workouts.isNotEmpty,
    );
    if (groups.isEmpty) {
      return ListView(
        padding: padding,
        children: [header, _emptyHome(context, ref)],
      );
    }
    return ReorderableListView.builder(
      padding: padding,
      header: header,
      buildDefaultDragHandles: false,
      itemCount: groups.length,
      proxyDecorator: homeReorderProxy,
      onReorderItem: (from, to) {
        reorderHomeRow(ref, from, to);
      },
      itemBuilder: (context, index) {
        final group = groups[index];
        final id = group.isSection
            ? 's:${group.section}'
            : 'w:${group.workouts.single.id}';
        return KeyedSubtree(
          key: ValueKey(id),
          child: buildHomeGroup(
            context,
            ref,
            group,
            groupIndex: index,
            runs: runs,
            isPro: isPro,
          ),
        );
      },
    );
  }
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
