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
