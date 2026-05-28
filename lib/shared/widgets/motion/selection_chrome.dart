import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';

/// Animated selection checkbox overlay for grid tiles.
class MediaSelectionOverlay extends ConsumerWidget {
  const MediaSelectionOverlay({
    super.key,
    required this.selected,
    required this.inSelectionMode,
    required this.child,
  });

  final bool selected;
  final bool inSelectionMode;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = AppMotion.of(context, ref);
    final pad = selected ? 8.0 : 0.0;
    final radius = selected ? 8.0 : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: motion.fadeFast,
          curve: motion.enterCurve,
          padding: EdgeInsets.all(pad),
          color: selected
              ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: child,
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: AnimatedOpacity(
            duration: motion.fadeFast,
            opacity: selected ? 1 : 0,
            child: AnimatedScale(
              duration: motion.fadeFast,
              scale: selected ? 1 : 0.6,
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedOpacity(
            duration: motion.fadeFast,
            opacity: inSelectionMode && !selected ? 0.08 : 0,
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      ],
    );
  }
}

/// Slides/fades a bottom action bar when selection mode toggles.
class AnimatedSelectionBar extends StatelessWidget {
  const AnimatedSelectionBar({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: visible ? child : const SizedBox.shrink(),
      ),
    );
  }
}

/// Cross-fades between normal and selection app bar titles/actions.
class AnimatedSelectionAppBar extends ConsumerWidget
    implements PreferredSizeWidget {
  const AnimatedSelectionAppBar({
    super.key,
    required this.inSelectionMode,
    required this.selectionTitle,
    required this.normalTitle,
    required this.onCloseSelection,
    required this.selectionActions,
    this.normalActions = const [],
    this.normalLeading,
  });

  final bool inSelectionMode;
  final Widget selectionTitle;
  final Widget normalTitle;
  final VoidCallback onCloseSelection;
  final List<Widget> selectionActions;
  final List<Widget> normalActions;
  final Widget? normalLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = AppMotion.of(context, ref);

    return AppBar(
      title: AnimatedSwitcher(
        duration: motion.fade,
        switchInCurve: motion.enterCurve,
        switchOutCurve: motion.exitCurve,
        child: inSelectionMode
            ? KeyedSubtree(
                key: const ValueKey('selection'),
                child: selectionTitle,
              )
            : KeyedSubtree(key: const ValueKey('normal'), child: normalTitle),
      ),
      leading: inSelectionMode
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: onCloseSelection,
            )
          : normalLeading,
      actions: inSelectionMode ? selectionActions : normalActions,
    );
  }
}
