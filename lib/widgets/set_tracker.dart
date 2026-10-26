import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';
import 'number_stepper.dart';

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
/// correct), the active set with steppers, and upcoming sets dimmed.
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
  });

  final Exercise exercise;

  /// Logs already recorded for [exercise].
  final List<SetLog> logs;

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

  SetLog? _logFor(int setNumber) {
    for (final log in widget.logs) {
      if (log.setNumber == setNumber) {
        return log;
      }
    }
    return null;
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
    final log = _logFor(setNumber);
    final controlsThisSet = _controlsSet() == setNumber;
    final key = _rowKey(setNumber);

    if (log != null) {
      return _SetRow(
        key: key,
        setNumber: setNumber,
        state: _RowState.done,
        highlighted: controlsThisSet,
        onTap: () => setState(() => _editingSet = setNumber),
        trailing: _LoggedLabel(log: log),
      );
    }

    if (setNumber == widget.activeSetNumber && !widget.isResting) {
      return _SetRow(
        key: key,
        setNumber: setNumber,
        state: _RowState.active,
        highlighted: true,
      );
    }

    return _SetRow(key: key, setNumber: setNumber, state: _RowState.upcoming);
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

    final log = _logFor(_controlsSet());
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

enum _RowState { done, active, upcoming }

class _SetRow extends StatelessWidget {
  const _SetRow({
    super.key,
    required this.setNumber,
    required this.state,
    this.highlighted = false,
    this.trailing,
    this.onTap,
  });

  final int setNumber;
  final _RowState state;
  final bool highlighted;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUpcoming = state == _RowState.upcoming;

    final icon = switch (state) {
      _RowState.done => Icons.check_circle_rounded,
      _RowState.active => Icons.radio_button_checked_rounded,
      _RowState.upcoming => Icons.radio_button_unchecked_rounded,
    };
    final iconColor = isUpcoming
        ? colorScheme.onSurface.withValues(alpha: 0.3)
        : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: highlighted
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: context.skinLook.cornerRadiusSmall,
        child: InkWell(
          borderRadius: context.skinLook.cornerRadiusSmall,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Set $setNumber',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: highlighted
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isUpcoming
                          ? colorScheme.onSurface.withValues(alpha: 0.45)
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reps and kg on one row, small enough for a phone-width window.
class _SetEditor extends StatelessWidget {
  const _SetEditor({
    required this.reps,
    required this.weightKg,
    required this.onRepsChanged,
    required this.onWeightChanged,
  });

  final int reps;
  final double weightKg;
  final ValueChanged<double> onRepsChanged;
  final ValueChanged<double> onWeightChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: NumberStepper(
            label: 'Reps',
            value: reps.toDouble(),
            max: 999,
            compact: true,
            onChanged: onRepsChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: NumberStepper(
            label: 'Weight',
            unit: 'kg',
            value: weightKg,
            step: 2.5,
            decimals: 1,
            max: 999,
            compact: true,
            onChanged: onWeightChanged,
          ),
        ),
      ],
    );
  }
}

class _LoggedLabel extends StatelessWidget {
  const _LoggedLabel({required this.log});

  final SetLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = log.hasWeight
        ? '${log.reps} × ${SetLog.formatKg(log.weightKg!)} kg'
        : '${log.reps} reps';
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
