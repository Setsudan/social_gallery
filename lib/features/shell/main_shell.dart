import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/shared/navigation/shell_nav_config.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onBranchSelected(WidgetRef ref, int branchIndex) {
    final isReselect = branchIndex == navigationShell.currentIndex;
    if (isReselect) {
      notifyTabScrollToTop(ref, branchIndex);
    }
    navigationShell.goBranch(branchIndex, initialLocation: isReselect);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryViewMode = ref.watch(
      settingsProvider.select((settings) => settings.galleryViewMode),
    );
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 800;

    ref.listen<bool>(
      settingsProvider.select((settings) => settings.galleryViewMode),
      (previous, next) {
        if (next &&
            navigationShell.currentIndex == kShellTabExplore) {
          navigationShell.goBranch(kShellTabHome);
        }
      },
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            _DesktopSidebar(
              galleryViewMode: galleryViewMode,
              selectedBranchIndex: navigationShell.currentIndex,
              onBranchSelected: (index) => _onBranchSelected(ref, index),
              onSettingsPressed: () => context.push('/settings'),
            ),
            Expanded(
              child: SafeArea(
                child: FloatingNavInsets(
                  overlayHeight: 0,
                  child: navigationShell,
                ),
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
          SafeArea(
            bottom: false,
            child: FloatingNavInsets(
              overlayHeight: overlayHeight,
              child: navigationShell,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingBottomNav(
              selectedBranchIndex: navigationShell.currentIndex,
              galleryViewMode: galleryViewMode,
              onBranchSelected: (index) => _onBranchSelected(ref, index),
              onSettingsPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.galleryViewMode,
    required this.selectedBranchIndex,
    required this.onBranchSelected,
    required this.onSettingsPressed,
  });

  final bool galleryViewMode;
  final int selectedBranchIndex;
  final ValueChanged<int> onBranchSelected;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destinations = shellNavDestinations(galleryViewMode: galleryViewMode);

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
          for (final destination in destinations)
            _SidebarItem(
              icon: destination.unselectedIcon,
              selectedIcon: destination.selectedIcon,
              label: destination.label,
              selected: selectedBranchIndex == destination.branchIndex,
              onTap: () => onBranchSelected(destination.branchIndex),
            ),
          _SidebarItem(
            icon: Icons.menu,
            selectedIcon: Icons.menu,
            label: 'Settings',
            selected: false,
            onTap: onSettingsPressed,
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
