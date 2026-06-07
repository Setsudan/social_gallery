import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/core/animation/app_motion.dart';

enum AppPageTransitionKind { fade, slideHorizontal, slideVertical }

const _shellPaths = {
  '/home',
  '/explore',
  '/discover',
};

const _modalPaths = {'/story_viewer', '/media_viewer'};

const _detailPaths = {
  '/post_detail',
  '/folder_profile',
  '/duplicates',
  '/duplicate_review',
};

AppPageTransitionKind _kindForLocation(String location) {
  final path = Uri.parse(location).path;
  if (_modalPaths.contains(path)) {
    return AppPageTransitionKind.slideVertical;
  }
  if (_detailPaths.contains(path)) {
    return AppPageTransitionKind.slideHorizontal;
  }
  if (_shellPaths.contains(path)) {
    return AppPageTransitionKind.fade;
  }
  if (path == '/startup') {
    return AppPageTransitionKind.fade;
  }
  return AppPageTransitionKind.slideHorizontal;
}

CustomTransitionPage<T> appTransitionPage<T>({
  required BuildContext context,
  required Ref ref,
  required GoRouterState state,
  required Widget child,
}) {
  final motion = AppMotion.read(context, ref);
  final kind = _kindForLocation(state.uri.toString());

  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: motion.transition,
    reverseTransitionDuration: motion.fade,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (!motion.enabled) return child;

      final curved = CurvedAnimation(
        parent: animation,
        curve: motion.enterCurve,
        reverseCurve: motion.exitCurve,
      );
      final fade = CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      );

      Widget transitionChild = child;
      switch (kind) {
        case AppPageTransitionKind.fade:
          transitionChild = FadeTransition(opacity: fade, child: child);
        case AppPageTransitionKind.slideHorizontal:
          transitionChild = SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: fade, child: child),
          );
        case AppPageTransitionKind.slideVertical:
          transitionChild = SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: fade, child: child),
          );
      }

      if (secondaryAnimation.status != AnimationStatus.dismissed) {
        return FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.92).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: motion.exitCurve,
            ),
          ),
          child: transitionChild,
        );
      }
      return transitionChild;
    },
  );
}

const PageTransitionsTheme oneUiPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
  },
);
