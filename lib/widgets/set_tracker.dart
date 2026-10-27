import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import 'number_stepper.dart';

part 'set_tracker_rows.dart';

/// What the user is entering for the set they are on right now.
class ActiveSetEntry {
  const ActiveSetEntry({required this.reps, required this.weightKg});

  final int reps;
  final double weightKg;

  ActiveSetEntry copyWith({int? reps, double? weightKg}) {
    return ActiveSetEntry(
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
    );
  }
}

/// Per-set log for the exercise on screen: done sets with reps × kg (tap to
/// correct), the active set with steppers, upcoming sets dimmed, and what
/// each set was last time.
class SetTracker extends StatefulWidget {
  const SetTracker({
    super.key,
    required this.exercise,
    required this.logs,
    required this.activeSetNumber,
    required this.activeEntry,
    required this.isResting,
    required this.onActiveEntryChanged,
    required this.onLoggedSetChanged,
    this.previousLogs = const [],
  });

  final Exercise exercise;

  /// Logs already recorded for [exercise].
  final List<SetLog> logs;

  /// What was logged for each set the last time this workout included this
  /// exercise. Empty when there is no earlier session.
  final List<SetLog> previousLogs;

  /// The set the user is about to do (SET phase) or just finished (REST).
  final int activeSetNumber;

  /// Values shown for the active set while in the SET phase.
  final ActiveSetEntry activeEntry;

  /// True during the rest after a set; the active set is then a logged one.
  final bool isResting;

  final ValueChanged<ActiveSetEntry> onActiveEntryChanged;
  final void Function(int setNumber, {int? reps, double? weightKg})
  onLoggedSetChanged;

  @override
  State<SetTracker> createState() => _SetTrackerState();
}

class _SetTrackerState extends State<SetTracker> {
  /// A completed set the user tapped to correct; null means the set just finished.
  int? _editingSet;
  final Map<int, GlobalKey> _rowKeys = {};

  @override
  void initState() {
    super.initState();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(covariant SetTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final exerciseChanged = oldWidget.exercise.id != widget.exercise.id;
    final setChanged = oldWidget.activeSetNumber != widget.activeSetNumber;
    if (exerciseChanged || setChanged) {
      _editingSet = null;
    }
    if (exerciseChanged) {
      _rowKeys.clear();
    }
    if (exerciseChanged ||
        setChanged ||
        oldWidget.isResting != widget.isResting) {
      _scheduleReveal();
    }
  }

  GlobalKey _rowKey(int setNumber) {
    return _rowKeys.putIfAbsent(setNumber, GlobalKey.new);
  }

  /// Brings the set being logged into view when it sits below the fold.
  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final target = _rowKeys[_controlsSet()]?.currentContext;
      if (target == null) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        alignment: 1,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  /// The set the steppers are changing. Rest starts on the set just finished.
  int _controlsSet() {
    if (!widget.isResting) {
      return widget.activeSetNumber;
    }
    return _editingSet ?? widget.activeSetNumber;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSets = widget.exercise.sets ?? 1;
    final controls = _controls();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Log',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var setNumber = 1; setNumber <= totalSets; setNumber++)
                    _buildRow(setNumber),
                ],
              ),
            ),
            if (controls != null) ...[const SizedBox(height: 6), controls],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(int setNumber) {
    final log = _logFor(widget.logs, setNumber);
    final previous = _logFor(widget.previousLogs, setNumber);
    final controlsThisSet = _controlsSet() == setNumber;
    final trailing = _trail(log, previous);

    if (log != null) {
      return _SetRow(
        key: _rowKey(setNumber),
        setNumber: setNumber,
        state: _RowState.done,
        highlighted: controlsThisSet,
        onTap: () => setState(() => _editingSet = setNumber),
        trailing: trailing,
      );
    }

    if (setNumber == widget.activeSetNumber && !widget.isResting) {
      return _SetRow(
        key: _rowKey(setNumber),
        setNumber: setNumber,
        state: _RowState.active,
        highlighted: true,
        trailing: trailing,
      );
    }

    return _SetRow(
      key: _rowKey(setNumber),
      setNumber: setNumber,
      state: _RowState.upcoming,
      trailing: trailing,
    );
  }

  /// Steppers for the set being entered, kept under the list so they stay visible.
  Widget? _controls() {
    if (!widget.isResting) {
      final entry = widget.activeEntry;
      return _SetEditor(
        reps: entry.reps,
        weightKg: entry.weightKg,
        onRepsChanged: (value) {
          widget.onActiveEntryChanged(entry.copyWith(reps: value.toInt()));
        },
        onWeightChanged: (value) {
          widget.onActiveEntryChanged(entry.copyWith(weightKg: value));
        },
      );
    }

    final log = _logFor(widget.logs, _controlsSet());
    if (log == null) {
      return null;
    }
    return _SetEditor(
      reps: log.reps,
      weightKg: log.weightKg ?? 0,
      onRepsChanged: (value) {
        widget.onLoggedSetChanged(log.setNumber, reps: value.toInt());
      },
      onWeightChanged: (value) {
        widget.onLoggedSetChanged(log.setNumber, weightKg: value);
      },
    );
  }
}

SetLog? _logFor(List<SetLog> logs, int setNumber) {
  for (final log in logs) {
    if (log.setNumber == setNumber) {
      return log;
    }
  }
  return null;
}

Widget? _trail(SetLog? log, SetLog? previous) {
  if (log == null && previous == null) {
    return null;
  }
  return _SetTrail(log: log, previous: previous);
}
