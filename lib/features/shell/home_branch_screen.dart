import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/features/gallery/gallery_screen.dart';
import 'package:social_gallery/features/home/home_screen.dart';

/// Shell branch 0: [HomeScreen] or [GalleryScreen] per gallery view mode setting.
class HomeBranchScreen extends ConsumerWidget {
  const HomeBranchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryViewMode = ref.watch(
      settingsProvider.select((settings) => settings.galleryViewMode),
    );
    return galleryViewMode ? const GalleryScreen() : const HomeScreen();
  }
}
