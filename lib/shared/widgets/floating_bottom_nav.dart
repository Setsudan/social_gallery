import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

/// Pill height + outer bottom margin from [FloatingBottomNav].
const double kFloatingNavBarExtent = 64;
const double kFloatingNavOuterBottomMargin = 16;

/// Extra scroll padding so the last row clears the overlay.
const double kFloatingNavScrollGap = 12;

class FloatingNavInsets extends InheritedWidget {
  const FloatingNavInsets({
    super.key,
    required this.overlayHeight,
    required super.child,
  });

  final double overlayHeight;

  static double overlayHeightOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FloatingNavInsets>();
    if (scope != null) {
      return scope.overlayHeight;
    }
    return MediaQuery.viewPaddingOf(context).bottom;
  }

  static EdgeInsets scrollPadding(BuildContext context) {
    return EdgeInsets.only(
      bottom: overlayHeightOf(context) + kFloatingNavScrollGap,
    );
  }

  @override
  bool updateShouldNotify(FloatingNavInsets oldWidget) {
    return overlayHeight != oldWidget.overlayHeight;
  }
}

double floatingNavOverlayHeight(BuildContext context) {
  return kFloatingNavBarExtent +
      kFloatingNavOuterBottomMargin +
      MediaQuery.viewPaddingOf(context).bottom;
}

class FloatingBottomNav extends ConsumerWidget {
  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    _NavItem(Icons.home_outlined, Icons.home),
    _NavItem(Icons.search_outlined, Icons.search),
    _NavItem(Icons.explore_outlined, Icons.explore),
    _NavItem(Icons.favorite_border, Icons.favorite),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = AppMotion.of(context, ref);
    final theme = Theme.of(context);
    final pillSelected = selectedIndex < _destinations.length
        ? selectedIndex
        : 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        OneUiSpacing.pageHorizontal,
        0,
        OneUiSpacing.pageHorizontal,
        kFloatingNavOuterBottomMargin +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: _OneUiNavShell(
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotWidth = constraints.maxWidth / 4;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedPositioned(
                        duration: motion.fade,
                        curve: motion.enterCurve,
                        left: slotWidth * pillSelected + (slotWidth - 48) / 2,
                        top: 8,
                        child: AnimatedContainer(
                          duration: motion.fade,
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(_destinations.length, (index) {
                          final item = _destinations[index];
                          final selected = selectedIndex == index;
                          return _NavIconButton(
                            selected: selected,
                            unselectedIcon: item.unselected,
                            selectedIcon: item.selected,
                            filledWhenSelected: index == 0 || index == 2,
                            onPressed: () => onDestinationSelected(index),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: OneUiSpacing.sm),
            _NavIconButton(
              selected: selectedIndex == 4,
              unselectedIcon: Icons.person_outline,
              selectedIcon: Icons.person_outline,
              filledWhenSelected: true,
              onPressed: () => onDestinationSelected(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIconButton extends ConsumerWidget {
  const _NavIconButton({
    required this.selected,
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.onPressed,
    this.filledWhenSelected = false,
  });

  final bool selected;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final VoidCallback onPressed;
  final bool filledWhenSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = AppMotion.of(context, ref);
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return PressableScale(
      scale: 0.9,
      onTap: onPressed,
      child: SizedBox(
        width: 48,
        height: 48,
        child: AnimatedScale(
          scale: selected ? 1.05 : 1.0,
          duration: motion.fadeFast,
          curve: motion.enterCurve,
          child: Icon(
            selected && filledWhenSelected ? selectedIcon : unselectedIcon,
            size: 26,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// One UI bottom bar: rounded top container on flat background.
class _OneUiNavShell extends StatelessWidget {
  const _OneUiNavShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 0,
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(OneUiRadii.xl),
        bottom: Radius.circular(OneUiRadii.pill),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        height: kFloatingNavBarExtent,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(OneUiRadii.xl),
            bottom: Radius.circular(OneUiRadii.pill),
          ),
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.unselected, this.selected);

  final IconData unselected;
  final IconData selected;
}
