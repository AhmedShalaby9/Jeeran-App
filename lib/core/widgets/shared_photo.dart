import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// A photo that flies from a card to the top of the next screen (a shared-element transition). Both ends use the same [tag];
/// the corners round and square off smoothly on the way, and only the picture flies (badges and buttons stay on their card).
class SharedPhoto extends StatelessWidget {
  final Object tag;
  final double fromRadius; // the card's corner
  final double toRadius; // the destination's corner
  final Widget child;

  const SharedPhoto({super.key, required this.tag, required this.child, this.fromRadius = 18, this.toRadius = 0});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      transitionOnUserGestures: true,
      flightShuttleBuilder: (context, animation, direction, fromContext, toContext) {
        final pushing = direction == HeroFlightDirection.push;
        final shown = (pushing ? toContext : fromContext).widget as Hero;
        return AnimatedBuilder(
          animation: animation,
          builder: (_, _) {
            final t = Curves.easeOutCubic.transform(pushing ? animation.value : 1 - animation.value);
            return ClipRRect(borderRadius: BorderRadius.circular(lerpDouble(fromRadius, toRadius, t)!), child: shown.child);
          },
        );
      },
      child: child,
    );
  }
}
