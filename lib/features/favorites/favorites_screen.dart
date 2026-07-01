import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
import 'package:social_gallery/features/favorites/favorites_providers.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_tab_page_scaffold.dart';

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
    final l10n = context.l10n;
    final favoritesAsync = ref.watch(favoritesStreamProvider);
    return favoritesAsync.when(
      data: (items) => OneUiTabPageScaffold(
        extendBody: true,
        isEmpty: items.isEmpty,
        empty: EmptyState(
          title: l10n.favoritesEmptyTitle,
          message: l10n.favoritesEmptyMessage,
          icon: Icons.favorite_border,
        ),
        body: MediaGrid(
          controller: _scrollController,
          items: items,
          onTap: (item) => openMediaViewer(
            context,
            ref,
            items: items,
            item: item,
          ),
        ),
      ),
      loading: () => const OneUiTabPageScaffold(
        extendBody: true,
        isLoading: true,
        body: SizedBox.shrink(),
      ),
      error: (e, _) => OneUiTabPageScaffold(
        extendBody: true,
        error: e,
        body: const SizedBox.shrink(),
      ),
    );
  }
}
