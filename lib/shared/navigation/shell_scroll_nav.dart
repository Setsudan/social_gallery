import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/shared/navigation/shell_nav_config.dart';
import 'package:social_gallery/shared/navigation/shell_tab_visibility.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';

/// Mobile shell body + bottom nav. Scroll-driven label collapse uses local
/// state so scrolling does not rebuild the entire [MainShell].
class ShellScrollNavHost extends ConsumerStatefulWidget {
  const ShellScrollNavHost({
    super.key,
    required this.navigationShell,
    required this.galleryViewMode,
  });

  final StatefulNavigationShell navigationShell;
  final bool galleryViewMode;

  @override
  ConsumerState<ShellScrollNavHost> createState() =>
      _ShellScrollNavHostState();
}

class _ShellScrollNavHostState extends ConsumerState<ShellScrollNavHost> {
  bool _labelsExpanded = true;
  Timer? _scrollThrottle;
  double _pendingScrollOffset = 0;

  @override
  void dispose() {
    _scrollThrottle?.cancel();
    super.dispose();
  }

  void _onBranchSelected(int branchIndex) {
    final isReselect = branchIndex == widget.navigationShell.currentIndex;
    if (isReselect) {
      notifyTabScrollToTop(ref, branchIndex);
      ref.read(tabScrollOffsetProvider(branchIndex).notifier).state = 0;
      setState(() => _labelsExpanded = true);
    }
    ref.read(activeShellTabProvider.notifier).state = branchIndex;
    widget.navigationShell.goBranch(branchIndex, initialLocation: isReselect);
    if (branchIndex == kShellTabExplore) {
      notifyExploreSearchReset(ref);
    }
    if (isReselect) return;
    final offset = ref.read(tabScrollOffsetProvider(branchIndex));
    final expanded = shellNavLabelsExpandedFromStoredOffset(offset);
    if (expanded != _labelsExpanded) {
      setState(() => _labelsExpanded = expanded);
    }
  }

  void _applyScrollOffset(
    double offset,
    int branchIndex, {
    bool forceStore = false,
  }) {
    final previous = ref.read(tabScrollOffsetProvider(branchIndex));
    final expanded = shellNavLabelsExpandedForOffset(
      offset,
      currentlyExpanded: _labelsExpanded,
    );
    // Skip provider writes that do not change collapse state and are tiny
    // (avoids notify storms while flinging near the threshold).
    if (!forceStore &&
        expanded == _labelsExpanded &&
        (offset - previous).abs() < 24) {
      return;
    }
    ref.read(tabScrollOffsetProvider(branchIndex).notifier).state = offset;
    if (expanded != _labelsExpanded) {
      setState(() => _labelsExpanded = expanded);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification) {
      return false;
    }
    if (notification.metrics.maxScrollExtent < 96) return false;

    final branchIndex = widget.navigationShell.currentIndex;
    final offset = notification.metrics.pixels;
    _pendingScrollOffset = offset;

    if (notification is ScrollEndNotification) {
      _scrollThrottle?.cancel();
      _scrollThrottle = null;
      _applyScrollOffset(offset, branchIndex, forceStore: true);
      return false;
    }

    _scrollThrottle ??= Timer(const Duration(milliseconds: 80), () {
      _scrollThrottle = null;
      if (!mounted) return;
      _applyScrollOffset(_pendingScrollOffset, branchIndex);
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final overlayHeight = floatingNavOverlayHeight(context);
    final hideBottomNav = ref.watch(exploreSearchOverlayOpenProvider) ||
        ref.watch(gallerySelectionActiveProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: FloatingNavInsets(
              overlayHeight: overlayHeight,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: widget.navigationShell,
              ),
            ),
          ),
          if (!hideBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: FloatingBottomNav(
                  labelsExpanded: _labelsExpanded,
                  selectedBranchIndex: widget.navigationShell.currentIndex,
                  galleryViewMode: widget.galleryViewMode,
                  onBranchSelected: _onBranchSelected,
                  onSettingsPressed: () => context.push('/settings'),
                  onAlbumsLongPress: widget.galleryViewMode
                      ? () {
                          AppHaptics.medium();
                          context.push(lockedAlbumsLocation);
                        }
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
