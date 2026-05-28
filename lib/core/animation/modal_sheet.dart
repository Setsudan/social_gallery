import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';

Future<T?> showAppModalBottomSheet<T>({
  required BuildContext context,
  required WidgetRef ref,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) {
  final motion = AppMotion.of(context, ref);
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: isScrollControlled,
    sheetAnimationStyle: AnimationStyle(
      duration: motion.enabled ? motion.fade : Duration.zero,
      reverseDuration: motion.enabled ? motion.fadeFast : Duration.zero,
    ),
    builder: builder,
  );
}
