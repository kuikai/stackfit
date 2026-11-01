import 'dart:async';

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

/// Plays a run cycle. With [travel] she walks left to right; without it she hops in place.
class ChibiRun extends StatefulWidget {
  const ChibiRun({super.key, required this.frames, this.travel = true});

  final List<String> frames;

  /// False keeps her in the middle for a celebrate hop.
  final bool travel;

  @override
  State<ChibiRun> createState() => _ChibiRunState();
}

class _ChibiRunState extends State<ChibiRun>
    with SingleTickerProviderStateMixin {
  static const _framesPerSecond = 8.0;
  static const _lap = Duration(milliseconds: 2800);
  static const _spriteHeight = 112.0;

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
        for (final path in widget.frames)
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: _run, builder: (context, _) => _lane());
  }

  Widget _lane() {
    if (!_framesReady || widget.frames.isEmpty) {
      return const SizedBox.expand();
    }
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
    final left = widget.travel
        ? -offscreen + span * _run.value
        : (laneWidth - 96) / 2;
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
              // Keep the pose that is already on screen until the next one
              // is ready, so a late decode cannot flash the gym through her.
              gaplessPlayback: true,
            ),
          ),
        ),
      ],
    );
  }
}
