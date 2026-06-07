import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/navigation/shell_nav_config.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

/// Pill height + outer bottom margin from [FloatingBottomNav].
const double kFloatingNavBarExtent = 64;
const double kFloatingNavOuterBottomMargin = 16;

/// Extra scroll padding so the last row clears the overlay.
const double kFloatingNavScrollGap = 12;

const double _navIconSlotWidth = 52;
const double _navIconSize = 48;
const double _settingsButtonWidth = 52;

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
    required this.selectedBranchIndex,
    required this.galleryViewMode,
    required this.onBranchSelected,
    required this.onSettingsPressed,
  });

  final int selectedBranchIndex;
  final bool galleryViewMode;
  final ValueChanged<int> onBranchSelected;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = AppMotion.of(context, ref);
    final theme = Theme.of(context);
    final destinations = shellNavDestinations(galleryViewMode: galleryViewMode);
    final selectedNavIndex =
        navIndexForBranch(selectedBranchIndex, galleryViewMode: galleryViewMode) ??
        0;
    final pillWidth = destinations.length * _navIconSlotWidth;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          OneUiSpacing.pageHorizontal,
          0,
          OneUiSpacing.pageHorizontal,
          kFloatingNavOuterBottomMargin +
              MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: _OneUiNavShell(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: pillWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedPositioned(
                      duration: motion.fade,
                      curve: motion.enterCurve,
                      left: _navIconSlotWidth * selectedNavIndex +
                          (_navIconSlotWidth - _navIconSize) / 2,
                      top: (kFloatingNavBarExtent - _navIconSize) / 2,
                      child: AnimatedContainer(
                        duration: motion.fade,
                        width: _navIconSize,
                        height: _navIconSize,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.14,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final destination in destinations)
                          SizedBox(
                            width: _navIconSlotWidth,
                            child: Center(
                              child: _NavIconButton(
                                selected: selectedNavIndex == destination.navIndex,
                                unselectedIcon: destination.unselectedIcon,
                                selectedIcon: destination.selectedIcon,
                                filledWhenSelected: destination.filledWhenSelected,
                                onPressed: () => onBranchSelected(
                                  destination.branchIndex,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: OneUiSpacing.xs),
              _NavIconButton(
                selected: false,
                unselectedIcon: Icons.menu,
                selectedIcon: Icons.menu,
                filledWhenSelected: false,
                onPressed: onSettingsPressed,
              ),
            ],
          ),
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
        width: _settingsButtonWidth,
        height: _navIconSize,
        child: Center(
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
      ),
    );
  }
}

/// Floating capsule nav bar with transparent fill and circular outline.
class _OneUiNavShell extends StatelessWidget {
  const _OneUiNavShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: kFloatingNavBarExtent,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(kFloatingNavBarExtent / 2),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.sm),
      child: child,
    );
  }
}
