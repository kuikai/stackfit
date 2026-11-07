import 'package:flutter/material.dart';

/// Grip that starts a drag as soon as a finger lands on it.
Widget homeDragHandle(int index) {
  return ReorderableDragStartListener(
    index: index,
    child: const Tooltip(
      message: 'Drag to move',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Icon(Icons.drag_handle_rounded),
      ),
    ),
  );
}

Widget homeReorderProxy(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final lift = Curves.easeInOut.transform(animation.value);
      return Material(
        elevation: 6 * lift,
        color: Colors.transparent,
        shadowColor: Colors.black54,
        child: child,
      );
    },
    child: child,
  );
}
