import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/pro_provider.dart';
import '../../providers/workouts_provider.dart';
import '../../widgets/fit_menu_button.dart';
import '../../widgets/folder_shell.dart';
import '../../widgets/home_reorder.dart';
import '../../widgets/workout_section_card.dart';
import '../../widgets/workout_tile.dart';
import 'continue_run_row.dart';
import 'home_actions.dart';

/// Home workout list. Open folder days share the same drag gaps as loose rows.
class HomeWorkoutList extends ConsumerStatefulWidget {
  const HomeWorkoutList({
    super.key,
    required this.groups,
    required this.runs,
    required this.looseRuns,
    required this.emptyHome,
  });

  final List<WorkoutHomeGroup> groups;
  final List<InProgressWorkout> runs;
  final List<InProgressWorkout> looseRuns;
  final Widget emptyHome;

  @override
  ConsumerState<HomeWorkoutList> createState() => _HomeWorkoutListState();
}

class _HomeWorkoutListState extends ConsumerState<HomeWorkoutList> {
  /// Folders start open so days can slide with the same gaps as Home.
  late Set<String> _openSections = {
    for (final group in widget.groups)
      if (group.isSection) group.section!,
  };

  @override
  void didUpdateWidget(covariant HomeWorkoutList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sections = {
      for (final group in widget.groups)
        if (group.isSection) group.section!,
    };
    _openSections = {
      for (final section in _openSections)
        if (sections.contains(section)) section,
    };
    for (final section in sections) {
      if (!_openSections.contains(section) &&
          !oldWidget.groups.any((group) => group.section == section)) {
        _openSections.add(section);
      }
    }
  }

  void _toggleSection(String section) {
    setState(() {
      if (_openSections.contains(section)) {
        _openSections.remove(section);
      } else {
        _openSections.add(section);
      }
    });
  }

  void _onReorderFlat(int from, int to) {
    final next = reorderHomeFlatRows(
      ref.read(workoutsProvider),
      _openSections,
      from,
      to,
    );
    // Fire-and-forget: _saveOrder updates state before awaiting disk I/O.
    unawaited(ref.read(workoutsProvider.notifier).replaceHomeOrder(next));
  }

  int _sectionGroupIndex(String section) {
    return widget.groups.indexWhere((group) => group.section == section);
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProProvider);
    final padding = context.pageGutter(top: 8, bottom: FitMenuButton.menuRoom);
    final header = buildHomeHeader(context, ref, looseRuns: widget.looseRuns);
    if (widget.groups.isEmpty) {
      return ListView(
        padding: padding,
        children: [header, widget.emptyHome],
      );
    }

    final rows = buildHomeFlatRows(widget.groups, _openSections);
    return ReorderableListView.builder(
      padding: padding,
      header: header,
      buildDefaultDragHandles: false,
      itemCount: rows.length,
      proxyDecorator: homeReorderProxy,
      onReorderItem: _onReorderFlat,
      itemBuilder: (context, index) {
        final row = rows[index];
        return KeyedSubtree(
          key: ValueKey(row.key),
          child: switch (row) {
            HomeFlatHeader(:final section, :final workouts) => _sectionHeader(
              context,
              ref,
              section: section,
              workouts: workouts,
              index: index,
              open: _openSections.contains(section),
            ),
            HomeFlatWorkout(:final workout, :final section) => section == null
                ? _looseWorkoutTile(
                    context,
                    ref,
                    workout,
                    flatIndex: index,
                    flatCount: rows.length,
                    runs: widget.runs,
                    isPro: isPro,
                    rows: rows,
                  )
                : _sectionDayTile(
                    context,
                    ref,
                    workout,
                    section: section,
                    flatIndex: index,
                    flatCount: rows.length,
                    runs: widget.runs,
                    isPro: isPro,
                    rows: rows,
                    isLastDay: _isLastSectionDay(rows, index, section),
                  ),
            HomeFlatExit() => _folderExitGap(context),
          },
        );
      },
    );
  }

  bool _isLastSectionDay(List<HomeFlatRow> rows, int index, String section) {
    if (index + 1 >= rows.length) {
      return true;
    }
    final next = rows[index + 1];
    // Exit row sits under the last day; still treat that day as the footer.
    if (next is HomeFlatExit) {
      return true;
    }
    return next is! HomeFlatWorkout || next.section != section;
  }

  Widget _sectionHeader(
    BuildContext context,
    WidgetRef ref, {
    required String section,
    required List<Workout> workouts,
    required int index,
    required bool open,
  }) {
    final groupIndex = _sectionGroupIndex(section);
    return WorkoutSectionCard(
      section: section,
      workouts: workouts,
      open: open,
      onToggleOpen: () => _toggleSection(section),
      // Closed folders drag as one Home row; open ones use day rows for gaps.
      dragIndex: open ? null : index,
      onMoveUp: groupIndex <= 0
          ? null
          : () => reorderHomeRow(ref, groupIndex, groupIndex - 1),
      onMoveDown: groupIndex < 0 || groupIndex >= widget.groups.length - 1
          ? null
          : () => reorderHomeRow(ref, groupIndex, groupIndex + 1),
      onRename: () => renameHomeSection(context, ref, section),
      onDissolve: () => dissolveHomeSection(context, ref, section),
      onAddWorkout: () => createHomeWorkout(context, ref, section: section),
    );
  }
}

/// Hit target under an open folder so drops can land on Home below the plan.
Widget _folderExitGap(BuildContext context) {
  return SizedBox(height: context.skinLook.listGap + 20);
}

Widget _looseWorkoutTile(
  BuildContext context,
  WidgetRef ref,
  Workout workout, {
  required int flatIndex,
  required int flatCount,
  required List<InProgressWorkout> runs,
  required bool isPro,
  required List<HomeFlatRow> rows,
}) {
  final inProgress = homeRunMatches(runs, workout);
  final canMoveUp = flatIndex > 0;
  final canMoveDown = flatIndex < flatCount - 1;
  return ReorderableDelayedDragStartListener(
    index: flatIndex,
    child: WorkoutTile(
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
      onMoveUp: canMoveUp
          ? () => _moveFlatRow(ref, rows, flatIndex, flatIndex - 1)
          : null,
      onMoveDown: canMoveDown
          ? () => _moveFlatRow(ref, rows, flatIndex, flatIndex + 1)
          : null,
      onDuplicate: isPro
          ? () => duplicateHomeWorkout(context, ref, workout)
          : null,
    ),
  );
}

Widget _sectionDayTile(
  BuildContext context,
  WidgetRef ref,
  Workout workout, {
  required String section,
  required int flatIndex,
  required int flatCount,
  required List<InProgressWorkout> runs,
  required bool isPro,
  required List<HomeFlatRow> rows,
  required bool isLastDay,
}) {
  final inProgress = homeRunMatches(runs, workout);
  final canMoveUp = flatIndex > 0;
  final canMoveDown = flatIndex < flatCount - 1;

  return ReorderableDelayedDragStartListener(
    index: flatIndex,
    child: FolderShell(
      role: isLastDay ? FolderShellRole.footer : FolderShellRole.middle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: 0.12,
            ),
          ),
          // Slight inset so days read as inside the folder, not sibling cards.
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: WorkoutTile(
              workout: workout,
              embedded: true,
              inProgress: inProgress,
              onStart: () => startHomeWorkout(context, ref, workout),
              onStartOver: inProgress
                  ? () => startHomeWorkout(context, ref, workout, fresh: true)
                  : null,
              onEdit: () => openHomeEditor(context, workoutId: workout.id),
              onHistory: () => openHomeWorkoutHistory(context, workout),
              onDelete: () => deleteHomeWorkout(context, ref, workout),
              onMoveToSection: () => moveHomeWorkout(context, ref, workout),
              onMoveUp: canMoveUp
                  ? () => _moveFlatRow(ref, rows, flatIndex, flatIndex - 1)
                  : null,
              onMoveDown: canMoveDown
                  ? () => _moveFlatRow(ref, rows, flatIndex, flatIndex + 1)
                  : null,
              onDuplicate: isPro
                  ? () => duplicateHomeWorkout(context, ref, workout)
                  : null,
            ),
          ),
        ],
      ),
    ),
  );
}

void _moveFlatRow(
  WidgetRef ref,
  List<HomeFlatRow> rows,
  int from,
  int to,
) {
  final open = {
    for (final row in rows)
      if (row is HomeFlatWorkout && row.section != null) row.section!,
  };
  final next = reorderHomeFlatRows(
    ref.read(workoutsProvider),
    open,
    from,
    to,
  );
  unawaited(ref.read(workoutsProvider.notifier).replaceHomeOrder(next));
}

Widget buildHomeHeader(
  BuildContext context,
  WidgetRef ref, {
  required List<InProgressWorkout> looseRuns,
}) {
  return Column(
    children: [
      for (final run in looseRuns)
        ContinueRunRow(
          run: run,
          onContinue: () => openInProgressRun(context, ref, run),
          onStartOver: () => openInProgressRun(context, ref, run, fresh: true),
        ),
    ],
  );
}

bool homeRunMatches(List<InProgressWorkout> runs, Workout workout) {
  for (final run in runs) {
    if (run.workout.id == workout.id &&
        run.canResume &&
        run.matchesLayout(workout)) {
      return true;
    }
  }
  return false;
}
