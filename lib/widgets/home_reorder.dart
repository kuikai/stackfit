import 'package:flutter/material.dart';

import '../models/models.dart';

/// Payload when a Home workout is dragged onto a folder or back onto Home.
class HomeWorkoutDrag {
  const HomeWorkoutDrag({required this.workout, this.fromSection});

  final Workout workout;

  /// Folder this row came from. Null means it was a loose Home row.
  final String? fromSection;
}

Widget homeReorderProxy(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      return _liftedHomeRow(
        lift: Curves.easeInOut.transform(animation.value),
        child: child,
      );
    },
    child: child,
  );
}

/// Hold a little longer than a Home reorder, then drag onto a folder or Home.
///
/// Same-list reorder still uses the short press, so it keeps the lifted tile.
/// The floating row here is that same tile, not a name chip.
Widget wrapHomeWorkoutDrag({
  required Workout workout,
  String? fromSection,
  required Widget Function() buildChild,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      return LongPressDraggable<HomeWorkoutDrag>(
        data: HomeWorkoutDrag(workout: workout, fromSection: fromSection),
        // After the usual 500ms long-press so same-list slide reorder still wins.
        delay: const Duration(milliseconds: 750),
        hapticFeedbackOnStart: true,
        rootOverlay: true,
        feedback: _liftedHomeRow(
          lift: 1,
          child: SizedBox(
            width: width.isFinite && width > 0 ? width : 320,
            child: IgnorePointer(child: buildChild()),
          ),
        ),
        childWhenDragging: IgnorePointer(
          child: Opacity(opacity: 0.35, child: buildChild()),
        ),
        child: buildChild(),
      );
    },
  );
}

Widget _liftedHomeRow({required double lift, Widget? child}) {
  return Material(
    elevation: 6 * lift,
    color: Colors.transparent,
    shadowColor: Colors.black54,
    child: child,
  );
}
