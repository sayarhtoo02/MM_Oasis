import 'package:flutter/material.dart';

class AnimationHelpers {
  static Route<T> slideTransition<T extends Object?>(
    Widget page, {
    Offset begin = const Offset(1.0, 0.0),
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(begin: begin, end: Offset.zero);
        final offsetAnimation = animation.drive(tween.chain(
          CurveTween(curve: Curves.easeInOut),
        ));
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  static Route<T> fadeTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
    );
  }

  static Route<T> scaleTransition<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: animation.drive(
            Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: Curves.easeInOut),
            ),
          ),
          child: child,
        );
      },
    );
  }
}
