import 'package:flutter/material.dart';
import 'package:social_gallery/l10n/app_localizations.dart';

/// Bottom shell branch indices (see [StatefulShellRoute] in router.dart).
const int kShellTabHome = 0;
const int kShellTabExplore = 1;
const int kShellTabDiscover = 2;

/// One bottom-nav or sidebar item mapped to a shell branch index.
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

List<ShellNavDestination> shellNavDestinations({
  required bool galleryViewMode,
  required AppLocalizations l10n,
}) {
  if (galleryViewMode) {
    return [
      ShellNavDestination(
        navIndex: 0,
        branchIndex: kShellTabHome,
        unselectedIcon: Icons.photo_library_outlined,
        selectedIcon: Icons.photo_library,
        label: l10n.navGallery,
        filledWhenSelected: true,
      ),
      ShellNavDestination(
        navIndex: 1,
        branchIndex: kShellTabExplore,
        unselectedIcon: Icons.photo_album_outlined,
        selectedIcon: Icons.photo_album,
        label: l10n.navAlbums,
        filledWhenSelected: true,
      ),
      ShellNavDestination(
        navIndex: 2,
        branchIndex: kShellTabDiscover,
        unselectedIcon: Icons.search_outlined,
        selectedIcon: Icons.search,
        label: l10n.navDiscover,
      ),
    ];
  }

  return [
    ShellNavDestination(
      navIndex: 0,
      branchIndex: kShellTabHome,
      unselectedIcon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: l10n.navHome,
      filledWhenSelected: true,
    ),
    ShellNavDestination(
      navIndex: 1,
      branchIndex: kShellTabExplore,
      unselectedIcon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: l10n.navExplore,
      filledWhenSelected: true,
    ),
    ShellNavDestination(
      navIndex: 2,
      branchIndex: kShellTabDiscover,
      unselectedIcon: Icons.search_outlined,
      selectedIcon: Icons.search,
      label: l10n.navDiscover,
    ),
  ];
}

int? navIndexForBranch(
  int branchIndex, {
  required bool galleryViewMode,
  required AppLocalizations l10n,
}) {
  for (final dest in shellNavDestinations(
    galleryViewMode: galleryViewMode,
    l10n: l10n,
  )) {
    if (dest.branchIndex == branchIndex) return dest.navIndex;
  }
  return null;
}

int branchIndexForNav(
  int navIndex, {
  required bool galleryViewMode,
  required AppLocalizations l10n,
}) {
  return shellNavDestinations(galleryViewMode: galleryViewMode, l10n: l10n)
      .firstWhere((dest) => dest.navIndex == navIndex)
      .branchIndex;
}
