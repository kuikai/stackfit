import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Short swipe toward the leading edge, the same motion as marking a task done.
/// The row springs back. [onDelete] runs once, when the swipe passes the mark.
class LogRowSwipe extends StatefulWidget {
  const LogRowSwipe({super.key, required this.onDelete, required this.child});

  final VoidCallback onDelete;
  final Widget child;

  @override
  State<LogRowSwipe> createState() => _LogRowSwipeState();
}

class _LogRowSwipeState extends State<LogRowSwipe>
    with SingleTickerProviderStateMixin {
  static const double _trigger = 64;
  static const double _maxDrag = 96;

  late final AnimationController _controller;
  Animation<double>? _spring;
  double _drag = 0;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onSpringTick);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isRtl => Directionality.of(context) == TextDirection.rtl;

  /// Positive means toward the trailing edge. Delete is the other way.
  double _towardEnd(double dx) => _isRtl ? -dx : dx;

  void _onDragStart(DragStartDetails details) {
    _spring = null;
    _fired = false;
    _controller.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _drag = _limited(_drag + _towardEnd(details.delta.dx)));
    _fireIfPastTrigger();
  }

  void _onDragEnd(DragEndDetails details) {
    _fireFling(_towardEnd(details.primaryVelocity ?? 0));
    _springBack();
  }

  double _limited(double next) {
    if (next > 0) {
      return 0;
    }
    final distance = next.abs();
    if (distance <= _maxDrag) {
      return next;
    }
    return -(_maxDrag + (distance - _maxDrag) * 0.18);
  }

  void _fireIfPastTrigger() {
    if (_fired || _drag > -_trigger) {
      return;
    }
    _fire();
  }

  void _fireFling(double towardEndVelocity) {
    if (_fired || towardEndVelocity >= 0) {
      return;
    }
    _fire();
  }

  void _fire() {
    _fired = true;
    HapticFeedback.lightImpact();
    widget.onDelete();
  }

  void _springBack() {
    _spring = Tween<double>(
      begin: _drag,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward(from: 0);
  }

  void _onSpringTick() {
    final spring = _spring;
    if (!mounted || spring == null) {
      return;
    }
    setState(() => _drag = spring.value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _springBack,
      child: _drag == 0 ? widget.child : _slidingRow(),
    );
  }

  Widget _slidingRow() {
    final visual = _isRtl ? -_drag : _drag;
    final surface = Theme.of(context).colorScheme.surface;
    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(child: _background()),
          Transform.translate(
            offset: Offset(visual, 0),
            child: ColoredBox(color: surface, child: widget.child),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    final progress = (_drag.abs() / _trigger).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.errorContainer,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Opacity(
            opacity: progress,
            child: Icon(
              Icons.delete_outline_rounded,
              color: scheme.onErrorContainer,
            ),
          ),
        ),
      ),
    );
  }
}
