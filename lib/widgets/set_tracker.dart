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
  /// A completed set the user tapped to correct; null means none.
  int? _editingSet;

  @override
  void didUpdateWidget(covariant SetTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.id != widget.exercise.id ||
        oldWidget.activeSetNumber != widget.activeSetNumber) {
      _editingSet = null;
    }
  }

  SetLog? _logFor(int setNumber) {
    for (final log in widget.logs) {
      if (log.setNumber == setNumber) {
        return log;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSets = widget.exercise.sets ?? 1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Log',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            for (var setNumber = 1; setNumber <= totalSets; setNumber++)
              _buildRow(setNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(int setNumber) {
    final log = _logFor(setNumber);
    final isActive = setNumber == widget.activeSetNumber;

    if (isActive && !widget.isResting) {
      final entry = widget.activeEntry;
      return _SetRow(
        setNumber: setNumber,
        state: _RowState.active,
        editor: _SetEditor(
          reps: entry.reps,
          weightKg: entry.weightKg,
          onRepsChanged: (value) {
            widget.onActiveEntryChanged(entry.copyWith(reps: value.toInt()));
          },
          onWeightChanged: (value) {
            widget.onActiveEntryChanged(entry.copyWith(weightKg: value));
          },
        ),
      );
    }

    if (log != null) {
      final editing =
          _editingSet == setNumber ||
          (_editingSet == null && isActive && widget.isResting);
      return _SetRow(
        setNumber: setNumber,
        state: _RowState.done,
        onTap: () => setState(() => _editingSet = editing ? -1 : setNumber),
        trailing: editing ? null : _LoggedLabel(log: log),
        editor: editing
            ? _SetEditor(
                reps: log.reps,
                weightKg: log.weightKg ?? 0,
                onRepsChanged: (value) {
                  widget.onLoggedSetChanged(setNumber, reps: value.toInt());
                },
                onWeightChanged: (value) {
                  widget.onLoggedSetChanged(setNumber, weightKg: value);
                },
              )
            : null,
      );
    }

    return _SetRow(setNumber: setNumber, state: _RowState.upcoming);
  }
}

enum _RowState { done, active, upcoming }

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.setNumber,
    required this.state,
    this.trailing,
    this.editor,
    this.onTap,
  });

  final int setNumber;
  final _RowState state;
  final Widget? trailing;
  final Widget? editor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = state == _RowState.active;
    final isUpcoming = state == _RowState.upcoming;
    final highlighted = isActive || editor != null;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                if (editor != null) ...[const SizedBox(height: 6), editor!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reps and kg steppers side by side (wraps on narrow screens).
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
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        NumberStepper(
          label: 'Reps',
          value: reps.toDouble(),
          max: 999,
          onChanged: onRepsChanged,
        ),
        NumberStepper(
          label: 'Weight',
          unit: 'kg',
          value: weightKg,
          step: 2.5,
          decimals: 1,
          max: 999,
          onChanged: onWeightChanged,
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
