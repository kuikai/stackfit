part of 'set_tracker.dart';

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
                Expanded(child: _setName(theme, colorScheme, isUpcoming)),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _setName(ThemeData theme, ColorScheme colorScheme, bool isUpcoming) {
    return Text(
      'Set $setNumber',
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
        color: isUpcoming
            ? colorScheme.onSurface.withValues(alpha: 0.45)
            : colorScheme.onSurface,
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

/// Today's logged amount, with last time underneath when this set has one.
class _SetTrail extends StatelessWidget {
  const _SetTrail({this.log, this.previous});

  final SetLog? log;
  final SetLog? previous;

  @override
  Widget build(BuildContext context) {
    final today = log;
    final last = previous;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (today != null) _LoggedLabel(log: today),
        if (last != null) _LastTimeLabel(log: last),
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
    return Text(
      _amount(log),
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _LastTimeLabel extends StatelessWidget {
  const _LastTimeLabel({required this.log});

  final SetLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Last ${_amount(log)}',
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

String _amount(SetLog log) {
  if (log.hasWeight) {
    return '${log.reps} × ${SetLog.formatKg(log.weightKg!)} kg';
  }
  return '${log.reps} reps';
}
