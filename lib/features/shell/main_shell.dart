import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/shared/navigation/shell_nav_config.dart';
import 'package:social_gallery/shared/navigation/shell_scroll_nav.dart';
import 'package:social_gallery/shared/navigation/shell_tab_visibility.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/gradient_loading_screen.dart';

/// Root scaffold for the three-tab shell: bottom nav on mobile, sidebar on desktop.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  void _onBranchSelected(WidgetRef ref, int branchIndex) {
    ref.read(activeShellTabProvider.notifier).state = branchIndex;
    widget.navigationShell.goBranch(branchIndex);
    if (branchIndex == kShellTabExplore) {
      notifyExploreSearchReset(ref);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(activeShellTabProvider.notifier).state =
          widget.navigationShell.currentIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final galleryViewMode = ref.watch(
      settingsProvider.select((settings) => settings.galleryViewMode),
    );
    final sync = ref.watch(gallerySyncProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 800;

    ref.listen<bool>(
      settingsProvider.select((settings) => settings.galleryViewMode),
      (previous, next) {
        if (next &&
            widget.navigationShell.currentIndex == kShellTabExplore) {
          widget.navigationShell.goBranch(kShellTabHome);
        }
      },
    );

    if (isDesktop) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                _DesktopSidebar(
                  galleryViewMode: galleryViewMode,
                  selectedBranchIndex: widget.navigationShell.currentIndex,
                  onBranchSelected: (index) => _onBranchSelected(ref, index),
                  onSettingsPressed: () => context.push('/settings'),
                  onLockedAlbumsPressed: galleryViewMode
                      ? () {
                          AppHaptics.light();
                          context.push(lockedAlbumsLocation);
                        }
                      : null,
                ),
                Expanded(
                  child: SafeArea(
                    child: FloatingNavInsets(
                      overlayHeight: 0,
                      child: widget.navigationShell,
                    ),
                  ),
                ),
              ],
            ),
            if (sync.showOverlay)
              Positioned.fill(
                child: _SyncOverlayFade(sync: sync, ref: ref),
              ),
          ],
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ShellScrollNavHost(
          navigationShell: widget.navigationShell,
          galleryViewMode: galleryViewMode,
        ),
        if (sync.showOverlay)
          Positioned.fill(
            child: _SyncOverlayFade(sync: sync, ref: ref),
          ),
      ],
    );
  }
}

class _SyncOverlayFade extends StatelessWidget {
  const _SyncOverlayFade({required this.sync, required this.ref});

  final GallerySyncState sync;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: GradientLoadingScreen(
        message: sync.headline,
        detail: sync.detail,
        progress: sync.progress,
        processed: sync.total > 0 ? sync.processed : null,
        total: sync.total > 0 ? sync.total : null,
        error: sync.error,
        onSkip: () => ref.read(gallerySyncProvider.notifier).dismissOverlay(),
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
    this.onLockedAlbumsPressed,
  });

  static const double width = 240;

  final bool galleryViewMode;
  final int selectedBranchIndex;
  final ValueChanged<int> onBranchSelected;
  final VoidCallback onSettingsPressed;
  final VoidCallback? onLockedAlbumsPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final destinations = shellNavDestinations(
      galleryViewMode: galleryViewMode,
      l10n: l10n,
    );

    return SizedBox(
      width: width,
      child: DecoratedBox(
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
                l10n.appTitle,
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
            if (onLockedAlbumsPressed != null)
              _SidebarItem(
                icon: Icons.lock_outline,
                selectedIcon: Icons.lock,
                label: l10n.navLockedAlbums,
                selected: false,
                onTap: onLockedAlbumsPressed!,
              ),
            _SidebarItem(
              icon: Icons.menu,
              selectedIcon: Icons.menu,
              label: l10n.navSettings,
              selected: false,
              onTap: onSettingsPressed,
            ),
          ],
        ),
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

