import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
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
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final paginated = ref.read(favoritesPaginatedProvider);
    handlePaginatedScroll(
      _scrollController.position,
      isLoading: paginated.isLoading,
      hasMore: paginated.hasMore,
      loadMore: () =>
          ref.read(favoritesPaginatedProvider.notifier).loadMore(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final paginated = ref.watch(favoritesPaginatedProvider);
    final items = paginated.items;

    if (paginated.error != null && items.isEmpty) {
      return OneUiTabPageScaffold(
        extendBody: true,
        error: paginated.error,
        body: const SizedBox.shrink(),
      );
    }

    if (items.isEmpty && paginated.isLoading) {
      return const OneUiTabPageScaffold(
        extendBody: true,
        isLoading: true,
        body: SizedBox.shrink(),
      );
    }

    return OneUiTabPageScaffold(
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
        isLoadingMore: paginated.isLoading && items.isNotEmpty,
        onTap: (item) => openMediaViewer(
          context,
          ref,
          items: items,
          item: item,
        ),
      ),
    );
  }
}
