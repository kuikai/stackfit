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
      framesPerSecond: _framesPerSecond,
    );
  }

  Widget _sprite(int frame, int partner, double laneWidth) {
    if (widget.partnerFrames.isNotEmpty && !widget.travel) {
      return _pair(frame, partner);
    }
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
            child: _mascot(widget.frames[frame]),
          ),
        ),
      ],
    );
  }

  Widget _pair(int frame, int partner) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _mascot(widget.frames[frame]),
          const SizedBox(width: 12),
          _mascot(widget.partnerFrames[partner]),
        ],
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
