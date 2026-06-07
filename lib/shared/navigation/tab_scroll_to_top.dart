import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';

export 'package:social_gallery/shared/navigation/shell_nav_config.dart'
    show kShellTabDiscover, kShellTabExplore, kShellTabHome;

/// Incremented when the user re-taps the active bottom nav tab.
final tabScrollToTopProvider = StateProvider.family<int, int>(
  (ref, tabIndex) => 0,
);

void notifyTabScrollToTop(WidgetRef ref, int tabIndex) {
  ref.read(tabScrollToTopProvider(tabIndex).notifier).update((n) => n + 1);
}

Future<void> animateScrollControllerToTop(
  ScrollController controller,
  AppMotion motion,
) async {
  if (!controller.hasClients) return;
  await controller.animateTo(
    0,
    duration: motion.fade,
    curve: motion.enterCurve,
  );
}

void listenForTabScrollToTop(
  WidgetRef ref,
  int tabIndex,
  ScrollController controller, {
  required AppMotion motion,
}) {
  ref.listen<int>(tabScrollToTopProvider(tabIndex), (previous, next) {
    if (previous != next && next > 0) {
      animateScrollControllerToTop(controller, motion);
    }
  });
}
