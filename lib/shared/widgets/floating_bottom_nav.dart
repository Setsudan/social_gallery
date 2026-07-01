import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/navigation/shell_nav_config.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

/// Pill height + outer bottom margin from [FloatingBottomNav].
const double kFloatingNavBarExtent = 64;
const double kFloatingNavBarCompactExtent = 52;
const double kFloatingNavOuterBottomMargin = 14;

/// Extra scroll padding so the last row clears the overlay.
const double kFloatingNavScrollGap = 12;

const double _navItemSlotWidth = 72;
const double _navItemSlotCompactWidth = 56;
const double _navItemInnerWidth = 64;
const double _navItemInnerCompactWidth = 48;
const double _navItemInnerHeight = 48;
const double _navItemInnerCompactHeight = 40;
const double _navIconSize = 20;
const double _settingsItemWidth = 64;

double _lerp(double compact, double expanded, double t) {
  return compact + (expanded - compact) * t;
}

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

class FloatingBottomNav extends ConsumerStatefulWidget {
  const FloatingBottomNav({
    super.key,
    required this.labelsExpanded,
    required this.selectedBranchIndex,
    required this.galleryViewMode,
    required this.onBranchSelected,
    required this.onSettingsPressed,
    this.onAlbumsLongPress,
  });

  final bool labelsExpanded;
  final int selectedBranchIndex;
  final bool galleryViewMode;
  final ValueChanged<int> onBranchSelected;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onAlbumsLongPress;

  @override
  ConsumerState<FloatingBottomNav> createState() => _FloatingBottomNavState();
}

class _FloatingBottomNavState extends ConsumerState<FloatingBottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expand;
  late Animation<double> _expandCurve;

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(
      vsync: this,
      value: widget.labelsExpanded ? 1.0 : 0.0,
    );
    _expandCurve = CurvedAnimation(
      parent: _expand,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(FloatingBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.labelsExpanded == oldWidget.labelsExpanded) return;
    if (widget.labelsExpanded) {
      _expand.forward();
    } else {
      _expand.reverse();
    }
  }

  @override
  void dispose() {
    _expand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context, ref);
    _expand.duration = motion.fade;

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final destinations = shellNavDestinations(
      galleryViewMode: widget.galleryViewMode,
      l10n: l10n,
    );
    final selectedNavIndex =
        navIndexForBranch(
          widget.selectedBranchIndex,
          galleryViewMode: widget.galleryViewMode,
          l10n: l10n,
        ) ??
        0;

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
        child: AnimatedBuilder(
          animation: _expandCurve,
          builder: (context, _) {
            final t = _expandCurve.value;
            final slotWidth = _lerp(_navItemSlotCompactWidth, _navItemSlotWidth, t);
            final innerWidth =
                _lerp(_navItemInnerCompactWidth, _navItemInnerWidth, t);
            final innerHeight =
                _lerp(_navItemInnerCompactHeight, _navItemInnerHeight, t);
            final barExtent =
                _lerp(kFloatingNavBarCompactExtent, kFloatingNavBarExtent, t);
            final pillWidth = destinations.length * slotWidth;
            final indicatorLeft = slotWidth * selectedNavIndex +
                (slotWidth - innerWidth) / 2;
            final indicatorTop = (barExtent - innerHeight) / 2;

            return _OneUiNavShell(
              barExtent: barExtent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRect(
                    child: SizedBox(
                      width: pillWidth,
                      height: barExtent,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          Positioned(
                            left: indicatorLeft,
                            top: indicatorTop,
                            child: Container(
                              width: innerWidth,
                              height: innerHeight,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(
                                  innerHeight / 2,
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (final destination in destinations)
                                SizedBox(
                                  width: slotWidth,
                                  height: barExtent,
                                  child: Center(
                                    child: _NavItemButton(
                                      expandT: t,
                                      selected: selectedNavIndex ==
                                          destination.navIndex,
                                      label: destination.label,
                                      unselectedIcon: destination.unselectedIcon,
                                      selectedIcon: destination.selectedIcon,
                                      filledWhenSelected:
                                          destination.filledWhenSelected,
                                      onPressed: () => widget.onBranchSelected(
                                        destination.branchIndex,
                                      ),
                                      onLongPress: widget.galleryViewMode &&
                                              destination.branchIndex ==
                                                  kShellTabExplore
                                          ? widget.onAlbumsLongPress
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: OneUiSpacing.xs),
                  _NavItemButton(
                    expandT: t,
                    selected: false,
                    label: l10n.navSettings,
                    unselectedIcon: Icons.menu,
                    selectedIcon: Icons.menu,
                    filledWhenSelected: false,
                    onPressed: widget.onSettingsPressed,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItemButton extends StatelessWidget {
  const _NavItemButton({
    required this.expandT,
    required this.selected,
    required this.label,
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.onPressed,
    this.filledWhenSelected = false,
    this.onLongPress,
  });

  final double expandT;
  final bool selected;
  final String label;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final VoidCallback onPressed;
  final bool filledWhenSelected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemWidth = _lerp(_navItemInnerCompactWidth, _settingsItemWidth, expandT);
    final itemHeight =
        _lerp(_navItemInnerCompactHeight, _navItemInnerHeight, expandT);
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
      onLongPress: onLongPress,
      child: SizedBox(
        width: itemWidth,
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected && filledWhenSelected ? selectedIcon : unselectedIcon,
              size: _navIconSize,
              color: iconColor,
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: expandT.clamp(0.001, 1.0),
                child: Opacity(
                  opacity: expandT,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating capsule nav bar with frosted fill and circular outline.
class _OneUiNavShell extends StatelessWidget {
  const _OneUiNavShell({
    required this.barExtent,
    required this.child,
  });

  final double barExtent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(barExtent / 2);

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
            height: barExtent,
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
