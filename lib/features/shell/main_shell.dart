import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 800;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                final isReselect = index == navigationShell.currentIndex;
                if (isReselect) {
                  notifyTabScrollToTop(ref, index);
                }
                navigationShell.goBranch(index, initialLocation: isReselect);
              },
            ),
            Expanded(
              child: FloatingNavInsets(
                overlayHeight: 0,
                child: navigationShell,
              ),
            ),
          ],
        ),
      );
    }

    final overlayHeight = floatingNavOverlayHeight(context);

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FloatingNavInsets(
            overlayHeight: overlayHeight,
            child: navigationShell,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNav(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                final isReselect = index == navigationShell.currentIndex;
                if (isReselect) {
                  notifyTabScrollToTop(ref, index);
                }
                navigationShell.goBranch(index, initialLocation: isReselect);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Social Gallery',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            selected: selectedIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),
          _SidebarItem(
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            label: 'Search',
            selected: selectedIndex == 1,
            onTap: () => onDestinationSelected(1),
          ),
          _SidebarItem(
            icon: Icons.explore_outlined,
            selectedIcon: Icons.explore,
            label: 'Explore',
            selected: selectedIndex == 2,
            onTap: () => onDestinationSelected(2),
          ),
          _SidebarItem(
            icon: Icons.favorite_border,
            selectedIcon: Icons.favorite,
            label: 'Favorites',
            selected: selectedIndex == 3,
            onTap: () => onDestinationSelected(3),
          ),
          _SidebarItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Profile',
            selected: selectedIndex == 4,
            onTap: () => onDestinationSelected(4),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
