import 'package:flutter/material.dart';

Widget homeReorderProxy(Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final lift = Curves.easeOut.transform(animation.value);
      // Keep lift gentle so release does not flash a hard elevation drop.
      return Material(
        elevation: 3 * lift,
        color: Colors.transparent,
        shadowColor: Colors.black38,
        child: Opacity(opacity: 0.92 + (0.08 * lift), child: child),
      );
    },
    child: child,
  );
}
