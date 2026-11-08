import 'package:flutter/material.dart';

import '../models/models.dart';

/// A short line of load over the dates of one workout.
///
/// Nothing is drawn for a single session.
class HistoryLoadChart extends StatelessWidget {
  const HistoryLoadChart({super.key, required this.sessions, this.padding});

  final List<CompletedSession> sessions;

  /// Inset around the line. The history section keeps the default.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final series = historyChartSeries(sessions);
    if (series == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w600,
    );
    final first = series.points.first.at;
    final last = series.points.last.at;

    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_unitLabel(series.unit), style: labelStyle),
          const SizedBox(height: 4),
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
      ),
    );
  }
}

String _unitLabel(HistoryChartUnit unit) {
  return unit == HistoryChartUnit.kilograms ? 'kg' : 'reps';
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
