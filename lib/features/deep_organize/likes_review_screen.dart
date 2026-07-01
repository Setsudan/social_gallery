import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/favorites/favorites_providers.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class LikesReviewScreen extends ConsumerStatefulWidget {
  const LikesReviewScreen({super.key});

  @override
  ConsumerState<LikesReviewScreen> createState() => _LikesReviewScreenState();
}

class _LikesReviewScreenState extends ConsumerState<LikesReviewScreen> {
  final _pageController = PageController();
  List<MediaItem> _shuffled = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shuffleItems(List<MediaItem> items) {
    final copy = [...items]..shuffle(Random());
    _shuffled = copy;
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesStreamProvider);
    final l10n = context.l10n;

    return favoritesAsync.when(
      loading: () => OneUiSubpageScaffold(
        title: l10n.discoverLikesReview,
        isLoading: true,
        body: const SizedBox.shrink(),
      ),
      error: (e, _) => OneUiSubpageScaffold(
        title: l10n.discoverLikesReview,
        error: e,
        body: const SizedBox.shrink(),
      ),
      data: (items) {
        if (_shuffled.length != items.length) {
          _shuffleItems(items);
        }

        if (items.isEmpty) {
          return OneUiSubpageScaffold(
            title: l10n.discoverLikesReview,
            subtitle: l10n.likesReviewEmptySubtitle,
            isEmpty: true,
            empty: EmptyState(
              title: l10n.likesReviewEmptyTitle,
              icon: Icons.favorite_border,
            ),
            body: const SizedBox.shrink(),
          );
        }

        return OneUiSubpageScaffold(
          title: l10n.discoverLikesReview,
          subtitle: l10n.likesReviewSubtitle,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final index = _pageController.hasClients
                    ? (_pageController.page ?? 0).round()
                    : 0;
                if (index < _shuffled.length) {
                  Share.share(
                    l10n.likesReviewSharing(_shuffled[index].displayName),
                  );
                }
              },
            ),
          ],
          body: PageView.builder(
            controller: _pageController,
            itemCount: _shuffled.length,
            itemBuilder: (context, index) {
              final item = _shuffled[index];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MediaThumbnail(assetId: item.uri, fit: BoxFit.contain),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
