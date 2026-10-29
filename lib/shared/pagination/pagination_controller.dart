/// Shared state for infinite-scroll lists (home feed, gallery, explore).
class PaginatedListState<T> {
  const PaginatedListState({
    this.items = const [],
    this.page = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<T> items;
  final int page;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  PaginatedListState<T> copyWith({
    List<T>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return PaginatedListState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Refresh clears the current page before fetching; append failures retain it.
/// Refresh may overlap an active request, matching existing notifier behavior.
Future<void> loadPaginatedPage<T>({
  required PaginatedListState<T> Function() readState,
  required void Function(PaginatedListState<T> state) writeState,
  required Future<List<T>> Function(int pageIndex) fetchPage,
  required int pageSize,
  required void Function(List<T> items) onPageLoaded,
  bool refresh = false,
}) async {
  if (readState().isLoading && !refresh) return;
  writeState(
    readState().copyWith(
      isLoading: true,
      clearError: true,
      page: refresh ? 0 : null,
      hasMore: refresh ? true : null,
      items: refresh ? const [] : null,
    ),
  );

  try {
    final pageIndex = refresh ? 0 : readState().page;
    final loadedItems = await fetchPage(pageIndex);
    final nextItems = refresh
        ? loadedItems
        : [...readState().items, ...loadedItems];
    writeState(
      PaginatedListState(
        items: nextItems,
        page: pageIndex + 1,
        isLoading: false,
        hasMore: loadedItems.length >= pageSize,
      ),
    );
    onPageLoaded(loadedItems);
  } catch (error) {
    writeState(
      readState().copyWith(
        isLoading: false,
        error: error.toString(),
        hasMore: refresh ? false : readState().hasMore,
      ),
    );
  }
}
