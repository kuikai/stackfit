import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Compact minus / value / plus control. The number is typed in place.
class NumberStepper extends StatefulWidget {
  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.step = 1,
    this.unit,
    this.decimals = 0,
    this.min = 0,
    this.max,
    this.compact = false,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String label;
  final double step;
  final String? unit;

  /// Decimal places kept when the field is committed (0 for reps, 1 for kg).
  final int decimals;

  /// Lowest value minus can reach.
  final num min;

  /// Highest value plus can reach. Omitted means no cap.
  final num? max;

  /// Smaller buttons and type, so two steppers fit on one row.
  final bool compact;

  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
    _focus = FocusNode();
    _focus.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(NumberStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focus.hasFocus) return;
    final formatted = _format(widget.value);
    if (_controller.text != formatted) {
      _controller.text = formatted;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _canDecrease => widget.value > widget.min;

  bool get _canIncrease {
    final max = widget.max;
    return max == null || widget.value < max;
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      _commit();
      return;
    }
    // Select after the tap places the cursor, so the next key replaces it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focus.hasFocus) return;
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  /// Steps from the number in the field, not a stale parent value.
  ///
  /// The focus listener is detached first so tapping plus does not commit
  /// the draft and then add the step a second time.
  void _step(double delta) {
    _focus.removeListener(_onFocusChange);
    _focus.unfocus();
    _focus.addListener(_onFocusChange);
    final base = _parse(_controller.text) ?? widget.value;
    _write(_bounded(base + delta));
  }

  void _commit() {
    final parsed = _parse(_controller.text);
    if (parsed == null) {
      _controller.text = _format(widget.value);
      return;
    }
    _write(_bounded(parsed));
  }

  /// Keeps the parent in sync while the keyboard is still open.
  ///
  /// On a phone, tapping Done does not take focus away from the field, so a
  /// save that waits for focus loss would log the old number.
  void _publishDraft(String raw) {
    final parsed = _parse(raw);
    if (parsed == null) return;
    final next = _bounded(parsed);
    if (next != widget.value) {
      widget.onChanged(next);
    }
  }

  void _write(double next) {
    final formatted = _format(next);
    if (_controller.text != formatted) {
      _controller.text = formatted;
    }
    if (next != widget.value) {
      widget.onChanged(next);
    }
  }

  double _bounded(double value) {
    var next = double.parse(value.toStringAsFixed(widget.decimals));
    final min = widget.min.toDouble();
    if (next < min) next = min;
    final max = widget.max?.toDouble();
    if (max != null && next > max) next = max;
    return next;
  }

  String _format(double value) {
    if (widget.decimals == 0 || value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(widget.decimals);
  }

  double? _parse(String raw) {
    final text = raw.trim().replaceAll(',', '.');
    if (text.isEmpty || text == '.') return null;
    return double.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final caption = widget.unit == null
        ? widget.label
        : '${widget.label} (${widget.unit})';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              (widget.compact
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelMedium)
                  ?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
        ),
        const SizedBox(height: 4),
        _stepRow(theme),
      ],
    );
  }

  Widget _stepRow(ThemeData theme) {
    final button = widget.compact ? 32.0 : 40.0;
    final icon = widget.compact ? 18.0 : 22.0;
    final less = _StepButton(
      icon: Icons.remove_rounded,
      tooltip: 'Less',
      size: button,
      iconSize: icon,
      onPressed: _canDecrease ? () => _step(-widget.step) : null,
    );
    final more = _StepButton(
      icon: Icons.add_rounded,
      tooltip: 'More',
      size: button,
      iconSize: icon,
      onPressed: _canIncrease ? () => _step(widget.step) : null,
    );
    final field = _valueField(theme);
    if (!widget.compact) {
      return Row(mainAxisSize: MainAxisSize.min, children: [less, field, more]);
    }
    return Row(
      children: [
        less,
        Expanded(child: field),
        more,
      ],
    );
  }

  Widget _valueField(ThemeData theme) {
    final field = TextField(
      controller: _controller,
      focusNode: _focus,
      textAlign: TextAlign.center,
      textAlignVertical: TextAlignVertical.center,
      keyboardType: TextInputType.numberWithOptions(
        decimal: widget.decimals > 0,
      ),
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      style:
          (widget.compact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.titleLarge)
              ?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
                height: 1,
              ),
      cursorColor: theme.colorScheme.primary,
      decoration: _fieldDecoration,
      inputFormatters: [_NumberInputFormatter(decimals: widget.decimals)],
      onChanged: _publishDraft,
      onSubmitted: (_) => _focus.unfocus(),
      onTapOutside: (_) => _focus.unfocus(),
    );
    if (widget.compact) {
      return SizedBox(height: 32, child: field);
    }
    return SizedBox(width: _fieldWidth, height: 40, child: field);
  }
}

/// Fits a value like 999.5 between the minus and plus buttons.
const _fieldWidth = 76.0;

const _fieldDecoration = InputDecoration(
  filled: false,
  isCollapsed: true,
  isDense: true,
  contentPadding: EdgeInsets.zero,
  border: InputBorder.none,
  enabledBorder: InputBorder.none,
  focusedBorder: InputBorder.none,
  disabledBorder: InputBorder.none,
  errorBorder: InputBorder.none,
  focusedErrorBorder: InputBorder.none,
);

/// Digits only, plus one decimal point when [decimals] is above 0.
class _NumberInputFormatter extends TextInputFormatter {
  const _NumberInputFormatter({required this.decimals});

  final int decimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = _sanitize(newValue.text);
    if (text == newValue.text) return newValue;
    final offset = newValue.selection.extentOffset.clamp(0, text.length);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  String _sanitize(String raw) {
    final buffer = StringBuffer();
    var sawSeparator = false;
    var fractionDigits = 0;
    for (final char in raw.split('')) {
      final isSeparator = char == ',' || char == '.';
      if (isSeparator && decimals > 0 && !sawSeparator) {
        sawSeparator = true;
        buffer.write('.');
        continue;
      }
      if (isSeparator || !_isDigit(char)) continue;
      if (sawSeparator && fractionDigits >= decimals) continue;
      if (sawSeparator) fractionDigits++;
      buffer.write(char);
    }
    return buffer.toString();
  }
}

bool _isDigit(String char) {
  if (char.length != 1) return false;
  final code = char.codeUnitAt(0);
  return code >= 48 && code <= 57;
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 40,
    this.iconSize = 22,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton.filledTonal(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        style: IconButton.styleFrom(
          minimumSize: Size(size, size),
          fixedSize: Size(size, size),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
