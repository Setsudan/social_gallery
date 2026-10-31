import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/shared/pagination/pagination_controller.dart';

void main() {
  late PaginatedListState<int> state;
  late List<int> requestedPages;
  late List<List<int>> loadedPages;

  setUp(() {
    state = const PaginatedListState();
    requestedPages = [];
    loadedPages = [];
  });

  Future<void> load({
    bool refresh = false,
    Future<List<int>> Function(int)? fetchPage,
  }) => loadPaginatedPage<int>(
    readState: () => state,
    writeState: (nextState) => state = nextState,
    fetchPage: (pageIndex) {
      requestedPages.add(pageIndex);
      return fetchPage?.call(pageIndex) ??
          Future.value([pageIndex * 2, pageIndex * 2 + 1]);
    },
    pageSize: 2,
    onPageLoaded: loadedPages.add,
    refresh: refresh,
  );

  test('loads first page and appends later pages', () async {
    await load();
    expect(state.items, [0, 1]);
    expect(state.page, 1);
    expect(state.isLoading, isFalse);
    expect(state.hasMore, isTrue);
    await load();
    expect(state.items, [0, 1, 2, 3]);
    expect(state.page, 2);
    expect(requestedPages, [0, 1]);
    expect(loadedPages, [
      [0, 1],
      [2, 3],
    ]);
  });

  test('short and empty pages mark the end of the list', () async {
    await load(fetchPage: (_) async => [1]);
    expect(state.hasMore, isFalse);
    await load(refresh: true, fetchPage: (_) async => []);
    expect(state.items, isEmpty);
    expect(state.hasMore, isFalse);
  });

  test('refresh keeps items visible during fetch then replaces them', () async {
    await load();
    final response = Completer<List<int>>();
    final refreshing = load(refresh: true, fetchPage: (_) => response.future);
    expect(state.items, [0, 1]);
    expect(state.page, 1);
    expect(state.isLoading, isTrue);
    expect(state.isRefreshing, isTrue);
    expect(state.hasMore, isTrue);
    response.complete([9]);
    await refreshing;
    expect(state.items, [9]);
    expect(state.page, 1);
    expect(requestedPages, [0, 0]);
  });

  test('ignores a second append while loading', () async {
    final response = Completer<List<int>>();
    final loading = load(fetchPage: (_) => response.future);
    await load();
    expect(requestedPages, [0]);
    response.complete([1, 2]);
    await loading;
    expect(state.items, [1, 2]);
  });

  test('append error preserves existing items and permits retry', () async {
    await load();
    await load(fetchPage: (_) async => throw StateError('offline'));
    expect(state.items, [0, 1]);
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.error, contains('offline'));
    await load();
    expect(state.error, isNull);
    expect(state.items, [0, 1, 2, 3]);
  });

  test('refresh error preserves items and hasMore', () async {
    await load();
    await load(
      refresh: true,
      fetchPage: (_) async => throw StateError('offline'),
    );
    expect(state.items, [0, 1]);
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
    expect(state.error, contains('offline'));
    expect(loadedPages.length, 1);
  });

  test(
    'preserves overlapping refresh and append completion behavior',
    () async {
      final firstResponse = Completer<List<int>>();
      final refreshResponse = Completer<List<int>>();
      final loading = load(fetchPage: (_) => firstResponse.future);
      final refreshing = load(
        refresh: true,
        fetchPage: (_) => refreshResponse.future,
      );
      refreshResponse.complete([8, 9]);
      await refreshing;
      firstResponse.complete([1, 2]);
      await loading;
      expect(state.items, [8, 9, 1, 2]);
      expect(state.page, 1);
    },
  );

  test('copyWith preserves fields and clears errors explicitly', () {
    state = const PaginatedListState(items: [1], page: 2, error: 'failure');
    expect(state.copyWith(isLoading: true).error, 'failure');
    final clearedState = state.copyWith(clearError: true);
    expect(clearedState.error, isNull);
    expect(clearedState.items, [1]);
    expect(clearedState.page, 2);
  });
}
