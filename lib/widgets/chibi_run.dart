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

/// Plays a run cycle and walks it from off the left to off the right.
class ChibiRun extends StatefulWidget {
  const ChibiRun({super.key, required this.frames});

  final List<String> frames;

  @override
  State<ChibiRun> createState() => _ChibiRunState();
}

class _ChibiRunState extends State<ChibiRun>
    with SingleTickerProviderStateMixin {
  static const _framesPerSecond = 8.0;
  static const _lap = Duration(milliseconds: 2800);
  static const _spriteHeight = 112.0;

  late final AnimationController _run;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(vsync: this, duration: _lap)..repeat();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _run, builder: (context, _) => _lane());
  }

  Widget _lane() {
    final elapsed = _run.value * _lap.inMilliseconds / 1000;
    final frame = runFrameIndex(
      elapsedSeconds: elapsed,
      frameCount: widget.frames.length,
      framesPerSecond: _framesPerSecond,
    );
    return LayoutBuilder(
      builder: (context, constraints) => _sprite(frame, constraints.maxWidth),
    );
  }

  Widget _sprite(int frame, double laneWidth) {
    const offscreen = 72.0;
    final span = laneWidth + offscreen * 2;
    final left = -offscreen + span * _run.value;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: left,
          bottom: 0,
          child: IgnorePointer(
            child: Image.asset(
              widget.frames[frame],
              height: _spriteHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ],
    );
  }
}
