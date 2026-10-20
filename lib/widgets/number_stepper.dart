import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact minus / value / plus control. Tap the value to type it.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.step = 1,
    this.unit,
    this.decimals = 0,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String label;
  final double step;
  final String? unit;

  /// Decimal places allowed when typing (0 for reps, 1 for kg).
  final int decimals;

  String get _display {
    if (decimals == 0 || value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          unit == null ? label : '$label ($unit)',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              tooltip: 'Less',
              onPressed:
                  value - step >= 0 ? () => onChanged(value - step) : null,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _typeValue(context),
              child: SizedBox(
                width: 64,
                height: 40,
                child: Center(
                  child: Text(
                    _display,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              tooltip: 'More',
              onPressed: () => onChanged(value + step),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _typeValue(BuildContext context) async {
    final controller = TextEditingController(text: _display);
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(unit == null ? label : '$label ($unit)'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(
              decimal: decimals > 0,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                decimals > 0 ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
              ),
            ],
            onSubmitted: (_) => Navigator.of(context).pop(_parse(controller)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_parse(controller)),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null) {
      onChanged(result);
    }
  }

  double? _parse(TextEditingController controller) {
    final text = controller.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) {
      return null;
    }
    return decimals == 0 ? parsed.roundToDouble() : parsed;
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton.filledTonal(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
      ),
    );
  }
}
