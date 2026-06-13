import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/navigation/shell_nav_config.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

/// Pill height + outer bottom margin from [FloatingBottomNav].
const double kFloatingNavBarExtent = 64;
const double kFloatingNavOuterBottomMargin = 14;

/// Extra scroll padding so the last row clears the overlay.
const double kFloatingNavScrollGap = 12;

const double _navItemSlotWidth = 72;
const double _navItemInnerWidth = 64;
const double _navItemInnerHeight = 48;
const double _navIconSize = 20;
const double _settingsItemWidth = 64;

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
    final pillWidth = destinations.length * _navItemSlotWidth;

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
                      left: _navItemSlotWidth * selectedNavIndex +
                          (_navItemSlotWidth - _navItemInnerWidth) / 2,
                      top: (kFloatingNavBarExtent - _navItemInnerHeight) / 2,
                      child: AnimatedContainer(
                        duration: motion.fade,
                        width: _navItemInnerWidth,
                        height: _navItemInnerHeight,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius: BorderRadius.circular(
                            _navItemInnerHeight / 2,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final destination in destinations)
                          SizedBox(
                            width: _navItemSlotWidth,
                            child: Center(
                              child: _NavItemButton(
                                selected:
                                    selectedNavIndex == destination.navIndex,
                                label: destination.label,
                                unselectedIcon: destination.unselectedIcon,
                                selectedIcon: destination.selectedIcon,
                                filledWhenSelected:
                                    destination.filledWhenSelected,
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
              _NavItemButton(
                selected: false,
                label: 'Settings',
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

class _NavItemButton extends ConsumerWidget {
  const _NavItemButton({
    required this.selected,
    required this.label,
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.onPressed,
    this.filledWhenSelected = false,
  });

  final bool selected;
  final String label;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final VoidCallback onPressed;
  final bool filledWhenSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motion = AppMotion.of(context, ref);
    final theme = Theme.of(context);
    final iconColor = selected
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 9,
      height: 1.0,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      color: selected
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
    );

    return PressableScale(
      scale: 0.9,
      onTap: onPressed,
      child: SizedBox(
        width: _settingsItemWidth,
        height: _navItemInnerHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.05 : 1.0,
                duration: motion.fadeFast,
                curve: motion.enterCurve,
                child: Icon(
                  selected && filledWhenSelected ? selectedIcon : unselectedIcon,
                  size: _navIconSize,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating capsule nav bar with frosted fill and circular outline.
class _OneUiNavShell extends StatelessWidget {
  const _OneUiNavShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(kFloatingNavBarExtent / 2);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.65),
            borderRadius: radius,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: SizedBox(
            height: kFloatingNavBarExtent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.sm),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
