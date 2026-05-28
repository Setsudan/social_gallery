import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesStreamProvider);
    final motion = AppMotion.of(context, ref);
    listenForTabScrollToTop(
      ref,
      kShellTabFavorites,
      _scrollController,
      motion: motion,
    );

    return Scaffold(
      extendBody: true,
      body: favoritesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OneUiPageHeader(title: 'Favorites'),
                Expanded(
                  child: EmptyState(
                    title: 'No favorites yet',
                    message: 'Double-tap a post on Home to favorite it.',
                    icon: Icons.favorite_border,
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OneUiPageHeader(title: 'Favorites'),
              Expanded(
                child: MediaGrid(
                  controller: _scrollController,
                  items: items,
                  onTap: (item) => context.push(
                    mediaViewerLocation(
                      item.uri,
                      mediaId: item.id,
                      favorite: true,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OneUiPageHeader(title: 'Favorites'),
            Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OneUiPageHeader(title: 'Favorites'),
            Expanded(
              child: EmptyState(
                title: 'Could not load favorites',
                message: e.toString(),
                icon: Icons.error_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final favoritesStreamProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(mediaRepositoryProvider).watchFavorites();
});
