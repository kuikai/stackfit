import 'package:flutter/material.dart';

/// Fade and a short slide for every full-screen push.
///
/// The default zoom scales the whole page, including Home's picture, so the
/// change feels like a jump. Both screens stay up and ease across instead.
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  static const PageTransitionsTheme theme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: SoftPageTransitionsBuilder(),
      TargetPlatform.fuchsia: SoftPageTransitionsBuilder(),
      TargetPlatform.iOS: SoftPageTransitionsBuilder(),
      TargetPlatform.linux: SoftPageTransitionsBuilder(),
      TargetPlatform.macOS: SoftPageTransitionsBuilder(),
      TargetPlatform.windows: SoftPageTransitionsBuilder(),
    },
  );

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // When this route is on top again, never keep the "covered" fade. After
    // pushReplacement (timer → finish) the leave animation can stick at 1,
    // which leaves Home invisible and untappable over the city background.
    final leave = route.isCurrent
        ? const AlwaysStoppedAnimation<double>(0)
        : secondaryAnimation;

    return FadeTransition(
      opacity: _enterFade.animate(animation),
      child: SlideTransition(
        position: _enterSlide.animate(animation),
        child: FadeTransition(
          opacity: _leaveFade.animate(leave),
          child: SlideTransition(
            position: _leaveSlide.animate(leave),
            child: child,
          ),
        ),
      ),
    );
  }
}

final Animatable<double> _enterFade = CurveTween(curve: Curves.easeInOutCubic);

final Animatable<Offset> _enterSlide = Tween<Offset>(
  begin: const Offset(0.06, 0),
  end: Offset.zero,
).chain(CurveTween(curve: Curves.easeInOutCubic));

final Animatable<double> _leaveFade = Tween<double>(
  begin: 1,
  end: 0,
).chain(CurveTween(curve: Curves.easeInOutCubic));

final Animatable<Offset> _leaveSlide = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(-0.04, 0),
).chain(CurveTween(curve: Curves.easeInOutCubic));
