import 'package:flutter/material.dart';

/// Bottom shell branch indices (see [StatefulShellRoute] in router.dart).
const int kShellTabHome = 0;
const int kShellTabExplore = 1;
const int kShellTabDiscover = 2;

class ShellNavDestination {
  const ShellNavDestination({
    required this.navIndex,
    required this.branchIndex,
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.label,
    this.filledWhenSelected = false,
  });

  final int navIndex;
  final int branchIndex;
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final String label;
  final bool filledWhenSelected;
}

List<ShellNavDestination> shellNavDestinations({required bool galleryViewMode}) {
  if (galleryViewMode) {
    return const [
      ShellNavDestination(
        navIndex: 0,
        branchIndex: kShellTabHome,
        unselectedIcon: Icons.photo_library_outlined,
        selectedIcon: Icons.photo_library,
        label: 'Gallery',
        filledWhenSelected: true,
      ),
      ShellNavDestination(
        navIndex: 1,
        branchIndex: kShellTabExplore,
        unselectedIcon: Icons.photo_album_outlined,
        selectedIcon: Icons.photo_album,
        label: 'Albums',
        filledWhenSelected: true,
      ),
      ShellNavDestination(
        navIndex: 2,
        branchIndex: kShellTabDiscover,
        unselectedIcon: Icons.search_outlined,
        selectedIcon: Icons.search,
        label: 'Discover',
      ),
    ];
  }

  return const [
    ShellNavDestination(
      navIndex: 0,
      branchIndex: kShellTabHome,
      unselectedIcon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      filledWhenSelected: true,
    ),
    ShellNavDestination(
      navIndex: 1,
      branchIndex: kShellTabExplore,
      unselectedIcon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Explore',
      filledWhenSelected: true,
    ),
    ShellNavDestination(
      navIndex: 2,
      branchIndex: kShellTabDiscover,
      unselectedIcon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: 'Discover',
    ),
  ];
}

int? navIndexForBranch(int branchIndex, {required bool galleryViewMode}) {
  for (final dest in shellNavDestinations(galleryViewMode: galleryViewMode)) {
    if (dest.branchIndex == branchIndex) return dest.navIndex;
  }
  return null;
}

int branchIndexForNav(int navIndex, {required bool galleryViewMode}) {
  return shellNavDestinations(galleryViewMode: galleryViewMode)
      .firstWhere((dest) => dest.navIndex == navIndex)
      .branchIndex;
}
