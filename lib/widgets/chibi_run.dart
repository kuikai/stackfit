import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Which cell of a run cycle to show at [elapsedSeconds].
int runFrameIndex({
  required double elapsedSeconds,
  required int frameCount,
  double framesPerSecond = 8,
}) {
  if (frameCount <= 0) {
    return 0;
  }
  final index = (elapsedSeconds * framesPerSecond).floor();
  return index % frameCount;
}

/// Plays a run cycle. With [travel] she walks left to right; without it she
/// hops in place with a bounce and pastel sparkles for workout complete.
class ChibiRun extends StatefulWidget {
  const ChibiRun({
    super.key,
    required this.frames,
    this.partnerFrames = const [],
    this.travel = true,
  });

  final List<String> frames;

  /// Second mascot hopping beside [frames]. Used when a workout is finished.
  final List<String> partnerFrames;

  /// False keeps her in the middle for a celebrate hop.
  final bool travel;

  @override
  State<ChibiRun> createState() => _ChibiRunState();
}

class _ChibiRunState extends State<ChibiRun>
    with SingleTickerProviderStateMixin {
  static const _runFps = 8.0;
  static const _celebrateFps = 10.0;
  static const _lap = Duration(milliseconds: 2800);
  static const _runHeight = 112.0;
  static const _celebrateHeight = 148.0;

  late final AnimationController _run;
  var _framesReady = false;

  @override
  void initState() {
    super.initState();
    // Stay off screen until every pose is decoded. Starting now would swap in
    // each PNG while it is still loading, and that empty gap is the blink
    // on the first crossing.
    _run = AnimationController(vsync: this, duration: _lap);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_warmThenRun()),
    );
  }

  Future<void> _warmThenRun() async {
    if (!mounted || widget.frames.isEmpty) {
      return;
    }
    try {
      await Future.wait([
        for (final path in [...widget.frames, ...widget.partnerFrames])
          precacheImage(AssetImage(path), context),
      ]);
    } catch (_) {
      // One bad frame should not leave her stuck off the left edge.
    }
    if (!mounted) {
      return;
    }
    setState(() => _framesReady = true);
    unawaited(_run.repeat());
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  double get _fps => widget.travel ? _runFps : _celebrateFps;

  double get _spriteHeight =>
      widget.travel ? _runHeight : _celebrateHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _run, builder: (context, _) => _lane());
  }

  Widget _lane() {
    if (!_framesReady || widget.frames.isEmpty) {
      return const SizedBox.expand();
    }
    final elapsed = _run.value * _lap.inMilliseconds / 1000;
    final frame = _frameAt(widget.frames, elapsed);
    final partner = _frameAt(widget.partnerFrames, elapsed);
    return LayoutBuilder(
      builder: (context, constraints) =>
          _sprite(frame, partner, constraints.maxWidth),
    );
  }

  int _frameAt(List<String> frames, double elapsed) {
    return runFrameIndex(
      elapsedSeconds: elapsed,
      frameCount: frames.length,
      framesPerSecond: _fps,
    );
  }

  Widget _sprite(int frame, int partner, double laneWidth) {
    if (widget.partnerFrames.isNotEmpty && !widget.travel) {
      return _pair(frame, partner);
    }
    if (!widget.travel) {
      return _celebrateSolo(frame);
    }
    const offscreen = 72.0;
    final span = laneWidth + offscreen * 2;
    final left = -offscreen + span * _run.value;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: left,
          bottom: 0,
          child: IgnorePointer(child: _mascot(widget.frames[frame])),
        ),
      ],
    );
  }

  /// In-place hop with a bounce and floating hearts / stars.
  Widget _celebrateSolo(int frame) {
    final hop = (math.sin(_run.value * math.pi * 4).abs()) * 18;
    final pulse = 1 + (math.sin(_run.value * math.pi * 4).abs()) * 0.06;
    final colors = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _CelebrateSparklesPainter(
              progress: _run.value,
              primary: colors.primary,
              secondary: colors.secondary,
            ),
          ),
        ),
        Positioned(
          bottom: hop,
          child: IgnorePointer(
            child: Transform.scale(
              scale: pulse,
              alignment: Alignment.bottomCenter,
              child: _mascot(widget.frames[frame]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pair(int frame, int partner) {
    final hop = (math.sin(_run.value * math.pi * 4).abs()) * 14;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(0, -hop),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _mascot(widget.frames[frame]),
            const SizedBox(width: 12),
            _mascot(widget.partnerFrames[partner]),
          ],
        ),
      ),
    );
  }

  Widget _mascot(String path) {
    return Image.asset(
      path,
      height: _spriteHeight,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // Keep the pose that is already on screen until the next one
      // is ready, so a late decode cannot flash the gym through her.
      gaplessPlayback: true,
    );
  }
}

/// Soft pastel hearts and stars that drift while she hops.
class _CelebrateSparklesPainter extends CustomPainter {
  _CelebrateSparklesPainter({
    required this.progress,
    required this.primary,
    required this.secondary,
  });

  final double progress;
  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final seeds = <(double, double, double, bool)>[
      (0.18, 0.55, 0.0, true),
      (0.78, 0.48, 0.12, false),
      (0.32, 0.28, 0.25, true),
      (0.68, 0.22, 0.38, false),
      (0.48, 0.12, 0.5, true),
      (0.12, 0.35, 0.62, false),
      (0.88, 0.38, 0.75, true),
      (0.55, 0.42, 0.88, false),
    ];
    for (final (nx, ny, phase, heart) in seeds) {
      final t = (progress + phase) % 1.0;
      final rise = ny - t * 0.55;
      if (rise < -0.05) {
        continue;
      }
      final x = nx * size.width;
      final y = rise * size.height;
      final fade = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = (heart ? primary : secondary).withValues(alpha: 0.55 * fade);
      final r = 5.0 + 4.0 * (1 - t);
      if (heart) {
        _heart(canvas, Offset(x, y), r, paint);
      } else {
        _star(canvas, Offset(x, y), r, paint);
      }
    }
  }

  void _heart(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path()
      ..moveTo(c.dx, c.dy + r * 0.35)
      ..cubicTo(
        c.dx - r,
        c.dy - r * 0.2,
        c.dx - r * 0.35,
        c.dy - r,
        c.dx,
        c.dy - r * 0.45,
      )
      ..cubicTo(
        c.dx + r * 0.35,
        c.dy - r,
        c.dx + r,
        c.dy - r * 0.2,
        c.dx,
        c.dy + r * 0.35,
      );
    canvas.drawPath(path, paint);
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final a = -math.pi / 2 + i * math.pi / 2;
      final outer = Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r);
      final mid = Offset(
        c.dx + math.cos(a + math.pi / 4) * r * 0.28,
        c.dy + math.sin(a + math.pi / 4) * r * 0.28,
      );
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(mid.dx, mid.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CelebrateSparklesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary;
  }
}
