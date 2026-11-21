import 'package:flutter/material.dart';

/// Native-feeling push (swipe back on iOS, predictive back on Android).
Route<T> pushRoute<T>(Widget page, {bool modal = false}) =>
    MaterialPageRoute<T>(builder: (_) => page, fullscreenDialog: modal);

/// Soft cross-fade, used when the launch screen hands over to the app.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
    );
