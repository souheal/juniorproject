import 'package:flutter/material.dart';

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case SlideDirection.right:
                begin = const Offset(1.0, 0.0);
                break;
              case SlideDirection.left:
                begin = const Offset(-1.0, 0.0);
                break;
              case SlideDirection.up:
                begin = const Offset(0.0, 1.0);
                break;
              case SlideDirection.down:
                begin = const Offset(0.0, -1.0);
                break;
            }

            final tween = Tween(begin: begin, end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));

            final fadeTween = Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

enum SlideDirection { right, left, up, down }

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(
                Tween(begin: 0.0, end: 1.0).chain(
                  CurveTween(curve: Curves.easeOut),
                ),
              ),
              child: child,
            );
          },
        );
}

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween(begin: 0.9, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutCubic));
            final fadeTween = Tween(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut));

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SharedAxisPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
              ),
            );

            final slideIn = Tween<Offset>(
              begin: const Offset(0.1, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            );

            return FadeTransition(
              opacity: fadeIn,
              child: SlideTransition(
                position: slideIn,
                child: child,
              ),
            );
          },
        );
}

class BottomSheetRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  BottomSheetRoute({required this.page})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: child,
            );
          },
        );
}
