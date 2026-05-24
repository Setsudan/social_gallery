import 'dart:ui';

import 'package:flutter/material.dart';

/// Pill height + outer bottom margin from [FloatingBottomNav].
const double kFloatingNavBarExtent = 56;
const double kFloatingNavOuterBottomMargin = 32;

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
    final scope = context.dependOnInheritedWidgetOfExactType<FloatingNavInsets>();
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

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    _NavItem(Icons.home_outlined, Icons.home),
    _NavItem(Icons.search, Icons.search),
    _NavItem(Icons.explore_outlined, Icons.explore),
    _NavItem(Icons.favorite_border, Icons.favorite),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        32,
        kFloatingNavOuterBottomMargin + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: _FloatingNavPill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_destinations.length, (index) {
                  final item = _destinations[index];
                  final selected = selectedIndex == index;
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: () => onDestinationSelected(index),
                    icon: Icon(
                      selected ? item.selected : item.unselected,
                      size: 24,
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            height: 56,
            child: _FloatingNavPill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => onDestinationSelected(4),
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: Icon(
                      selectedIndex == 4
                          ? Icons.person
                          : Icons.person_outline,
                      size: 24,
                      color: selectedIndex == 4
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavPill extends StatelessWidget {
  const _FloatingNavPill({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.35),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.unselected, this.selected);

  final IconData unselected;
  final IconData selected;
}
