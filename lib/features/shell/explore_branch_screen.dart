import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/features/albums/albums_screen.dart';
import 'package:social_gallery/features/explore/explore_screen.dart';

/// Shell branch 1: [ExploreScreen] or [AlbumsScreen] per gallery view mode setting.
class ExploreBranchScreen extends ConsumerWidget {
  const ExploreBranchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryViewMode = ref.watch(
      settingsProvider.select((settings) => settings.galleryViewMode),
    );
    return galleryViewMode ? const AlbumsScreen() : const ExploreScreen();
  }
}
