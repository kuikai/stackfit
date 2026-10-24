import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/pro_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/workouts_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/plan_library_tile.dart';
import '../../widgets/skin_artwork.dart';
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
    final groups = groupWorkoutsForHome(workouts);
    final background = ref.watch(settingsProvider).skin.backgroundAsset;

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
          if (background != null)
            Image.asset(
              background,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
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
                  child: workouts.isEmpty
                      ? EmptyState(
                          title: 'No workouts yet',
                          message:
                              'Create a custom workout with timer and set-based exercises, '
                              'or start from a ready-made plan.',
                          action: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    createHomeWorkout(context, ref),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create Workout'),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => openHomePlans(context),
                                icon: const Icon(
                                  Icons.auto_awesome_motion_outlined,
                                ),
                                label: const Text('Browse plans'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: context.pageGutter(top: 8, bottom: 100),
                          itemCount: groups.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return PlanLibraryTile(
                                onTap: () => openHomePlans(context),
                              );
                            }
                            return _buildGroup(
                              context,
                              ref,
                              groups[index - 1],
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

  Widget _buildGroup(
    BuildContext context,
    WidgetRef ref,
    WorkoutHomeGroup group, {
    required bool isPro,
  }) {
    if (!group.isSection) {
      final workout = group.workouts.single;
      return WorkoutTile(
        workout: workout,
        onStart: () => startHomeWorkout(context, workout),
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
      onStart: (workout) => startHomeWorkout(context, workout),
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
