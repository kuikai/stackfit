import 'package:flutter/material.dart';

import '../models/models.dart';

/// A short line of load over the dates of one workout, or one exercise.
///
/// Pick All or an exercise, and kilograms or sets. A hold workout charts
/// seconds. Fewer than two dates keeps the controls and a short note
/// instead of the line.
class HistoryLoadChart extends StatefulWidget {
  const HistoryLoadChart({super.key, required this.sessions, this.padding});

  final List<CompletedSession> sessions;

  /// Inset around the line. The history section keeps the default.
  final EdgeInsetsGeometry? padding;

  @override
  State<HistoryLoadChart> createState() => _HistoryLoadChartState();
}

class _HistoryLoadChartState extends State<HistoryLoadChart> {
  /// Menu value for the whole workout. Not an exercise id.
  static const _allExercises = '\u0000';

  String? _exerciseId;
  HistoryChartUnit _unit = HistoryChartUnit.kilograms;

  @override
  void didUpdateWidget(HistoryLoadChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _exerciseId;
    if (selected == null) {
      return;
    }
    for (final exercise in historyChartExercises(widget.sessions)) {
      if (exercise.id == selected) {
        return;
      }
    }
    _exerciseId = null;
  }

  @override
  Widget build(BuildContext context) {
    final exercises = historyChartExercises(widget.sessions);
    final holdsOnly = historyLogsAreHolds(
      widget.sessions,
      exerciseId: _exerciseId,
    );
    final unit = holdsOnly ? HistoryChartUnit.seconds : _unit;
    final series = historyChartSeries(
      widget.sessions,
      exerciseId: _exerciseId,
      unit: unit,
    );
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _controls(context, exercises, labelStyle, holdsOnly: holdsOnly),
          const SizedBox(height: 4),
          if (series == null)
            Text('One more time to see the line.', style: labelStyle)
          else if (_noWeight(series))
            Text('No weight logged.', style: labelStyle)
          else
            _line(series, labelStyle),
        ],
      ),
    );
  }

  bool _noWeight(HistoryChartSeries series) {
    if (series.unit != HistoryChartUnit.kilograms) {
      return false;
    }
    for (final point in series.points) {
      if (point.value > 0) {
        return false;
      }
    }
    return true;
  }

  Widget _controls(
    BuildContext context,
    List<HistoryChartExercise> exercises,
    TextStyle? labelStyle, {
    required bool holdsOnly,
  }) {
    final theme = Theme.of(context);
    final nameStyle = labelStyle?.copyWith(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _exerciseMenu(exercises, nameStyle),
          ),
        ),
        const SizedBox(width: 8),
        holdsOnly ? Text('seconds', style: labelStyle) : _unitSwitch(),
      ],
    );
  }

  Widget _exerciseMenu(
    List<HistoryChartExercise> exercises,
    TextStyle? nameStyle,
  ) {
    return PopupMenuButton<String>(
      tooltip: 'Exercise',
      padding: EdgeInsets.zero,
      initialValue: _exerciseId ?? _allExercises,
      onSelected: (value) {
        setState(() {
          _exerciseId = value == _allExercises ? null : value;
        });
      },
      itemBuilder: (context) {
        return [
          CheckedPopupMenuItem(
            value: _allExercises,
            checked: _exerciseId == null,
            child: const Text('All'),
          ),
          for (final exercise in exercises)
            CheckedPopupMenuItem(
              value: exercise.id,
              checked: exercise.id == _exerciseId,
              child: Text(_exerciseLabel(exercise)),
            ),
        ];
      },
      child: Row(
        children: [
          Flexible(
            child: Text(
              _selectedLabel(exercises),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nameStyle,
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 20, color: nameStyle?.color),
        ],
      ),
    );
  }

  String _selectedLabel(List<HistoryChartExercise> exercises) {
    final selected = _exerciseId;
    if (selected == null) {
      return 'All';
    }
    for (final exercise in exercises) {
      if (exercise.id == selected) {
        return _exerciseLabel(exercise);
      }
    }
    return 'All';
  }

  String _exerciseLabel(HistoryChartExercise exercise) {
    final name = exercise.name.trim();
    return name.isEmpty ? 'Exercise' : name;
  }

  Widget _unitSwitch() {
    return SegmentedButton<HistoryChartUnit>(
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
      ),
      segments: const [
        ButtonSegment(value: HistoryChartUnit.kilograms, label: Text('kg')),
        ButtonSegment(value: HistoryChartUnit.sets, label: Text('sets')),
      ],
      selected: {_unit},
      onSelectionChanged: (selected) {
        setState(() => _unit = selected.first);
      },
    );
  }

  Widget _line(HistoryChartSeries series, TextStyle? labelStyle) {
    final theme = Theme.of(context);
    final first = series.points.first.at;
    final last = series.points.last.at;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 64,
          child: CustomPaint(
            painter: _LoadLinePainter(
              points: series.points,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_axisDate(first, last), style: labelStyle),
            Text(_axisDate(last, first), style: labelStyle),
          ],
        ),
      ],
    );
  }
}

/// `5 Nov`, or with the time when both ends fall on the same day.
String _axisDate(DateTime date, DateTime other) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  final otherLocal = other.toLocal();
  final day = '${local.day} ${months[local.month - 1]}';
  final sameDay =
      local.year == otherLocal.year &&
      local.month == otherLocal.month &&
      local.day == otherLocal.day;
  if (!sameDay) {
    return day;
  }
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day · $hour:$minute';
}

class _LoadLinePainter extends CustomPainter {
  _LoadLinePainter({required this.points, required this.color});

  final List<HistoryChartPoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final offsets = _offsets(size);
    if (offsets.length < 2) {
      return;
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = color;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 3.5, dot);
    }
  }

  List<Offset> _offsets(Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) {
      return const [];
    }
    final start = points.first.at.millisecondsSinceEpoch.toDouble();
    final end = points.last.at.millisecondsSinceEpoch.toDouble();
    final values = points.map((point) => point.value);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return [
      for (var index = 0; index < points.length; index++)
        _pointOffset(
          point: points[index],
          index: index,
          startMs: start,
          endMs: end,
          minValue: minValue,
          maxValue: maxValue,
          size: size,
        ),
    ];
  }

  Offset _pointOffset({
    required HistoryChartPoint point,
    required int index,
    required double startMs,
    required double endMs,
    required double minValue,
    required double maxValue,
    required Size size,
  }) {
    const inset = 4.0;
    // Real dates set the gaps. Identical timestamps spread out evenly.
    final span = endMs - startMs;
    final xRatio = span == 0
        ? index / (points.length - 1)
        : (point.at.millisecondsSinceEpoch - startMs) / span;
    final valueSpan = maxValue - minValue;
    final yRatio = valueSpan == 0 ? 0.5 : (point.value - minValue) / valueSpan;
    return Offset(
      inset + (size.width - inset * 2) * xRatio,
      inset + (size.height - inset * 2) * (1 - yRatio),
    );
  }

  @override
  bool shouldRepaint(covariant _LoadLinePainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.points.length != points.length) {
      return true;
    }
    for (var index = 0; index < points.length; index++) {
      final previous = oldDelegate.points[index];
      final next = points[index];
      if (previous.at != next.at || previous.value != next.value) {
        return true;
      }
    }
    return false;
  }
}
