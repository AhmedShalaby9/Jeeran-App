import 'package:flutter/material.dart';

/// The route used when a card's photo flies into the next screen (see `SharedPhoto`): the page itself only fades, so the photo is
/// what the eye follows. Slightly slower than a plain push so the flight reads, and quicker on the way back.
Route<T> sharedElementRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.7, curve: Curves.easeOut), reverseCurve: Curves.easeIn),
        child: child,
      ),
    );
