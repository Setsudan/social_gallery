import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesStreamProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              title: 'No favorites yet',
              message: 'Double-tap a post on Home to favorite it.',
              icon: Icons.favorite_border,
            );
          }
          return MediaGrid(
            items: items,
            onTap: (item) => context.push(
              mediaViewerLocation(
                item.uri,
                mediaId: item.id,
                favorite: true,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          title: 'Could not load favorites',
          message: e.toString(),
          icon: Icons.error_outline,
        ),
      ),
    );
  }
}

final favoritesStreamProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(mediaRepositoryProvider).watchFavorites();
});
