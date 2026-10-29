import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/app/providers/data_providers.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';

const _mediaItem = MediaItem(
  id: 1,
  uri: 'asset-1',
  displayName: 'photo.jpg',
  folderName: 'Album',
  folderPath: '/album',
  dateAdded: 1,
  dateModified: 1,
  size: 100,
  mimeType: 'image/jpeg',
);

class _MediaRepository extends Fake implements MediaRepository {
  final requests =
      <({String source, int pageIndex, Object? argument, String? ocrQuery})>[];

  Future<List<MediaItem>> _page(
    String source,
    int pageIndex, {
    Object? argument,
    String? ocrQuery,
  }) async {
    requests.add((
      source: source,
      pageIndex: pageIndex,
      argument: argument,
      ocrQuery: ocrQuery,
    ));
    return [_mediaItem];
  }

  @override
  Future<List<FeedItem>> getHomeFeedPage(int page) async {
    await _page('home', page);
    return [
      const FeedItem(
        folderName: 'Album',
        folderPath: '/album',
        media: _mediaItem,
      ),
    ];
  }

  @override
  Future<List<MediaItem>> getGalleryMediaPage(int page) =>
      _page('gallery', page);

  @override
  Future<List<MediaItem>> getFavoritesPage(int page) =>
      _page('favorites', page);

  @override
  Future<List<MediaItem>> searchExplorePage(
    ExploreSearchQuery query,
    int page,
  ) => _page('explore', page, argument: query);

  @override
  Future<List<MediaItem>> getFolderMediaPage(String folderPath, int page) =>
      _page('folder', page, argument: folderPath);

  @override
  Future<List<MediaItem>> getContentKindPage(
    MediaContentKind kind,
    int page, {
    String? ocrQuery,
  }) => _page('contentKind', page, argument: kind, ocrQuery: ocrQuery);
}

void main() {
  late _MediaRepository mediaRepository;
  late ProviderContainer container;
  late List<({List<String> uris, int limit})> warmups;

  setUp(() {
    mediaRepository = _MediaRepository();
    warmups = [];
    container = ProviderContainer(
      overrides: [
        mediaRepositoryProvider.overrideWithValue(mediaRepository),
        paginatedMediaWarmupProvider.overrideWithValue((
          uris, {
          int limit = 16,
        }) {
          warmups.add((uris: uris.toList(), limit: limit));
        }),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> flushLoads() => Future<void>.delayed(Duration.zero);

  test(
    'home loads on creation, keeps favorite updates local, and uses warmup limit 12',
    () async {
      container.listen(homeFeedPaginatedProvider, (_, _) {});
      await flushLoads();
      expect(mediaRepository.requests.single.source, 'home');
      expect(mediaRepository.requests.single.pageIndex, 0);
      expect(warmups.single.uris, ['asset-1']);
      expect(warmups.single.limit, 12);
      container
          .read(homeFeedPaginatedProvider.notifier)
          .setItemFavorite(1, true);
      expect(
        container.read(homeFeedPaginatedProvider).items.single.media.isFavorite,
        isTrue,
      );
      expect(mediaRepository.requests.length, 1);
    },
  );

  test(
    'gallery and favorites use their respective fetchers and default warmup',
    () async {
      container.listen(galleryPaginatedProvider, (_, _) {});
      container.listen(favoritesPaginatedProvider, (_, _) {});
      await flushLoads();
      expect(mediaRepository.requests.map((request) => request.source), [
        'gallery',
        'favorites',
      ]);
      expect(warmups.map((warmup) => warmup.limit), [16, 16]);
      expect(container.read(galleryPaginatedProvider).items, [_mediaItem]);
      expect(container.read(favoritesPaginatedProvider).items, [_mediaItem]);
    },
  );

  test('explore and folder providers forward family arguments', () async {
    const query = ExploreSearchQuery(text: 'holiday');
    container.listen(explorePaginatedProvider(query), (_, _) {});
    container.listen(folderMediaPaginatedProvider('/album'), (_, _) {});
    await flushLoads();
    expect(mediaRepository.requests.map((request) => request.source), [
      'explore',
      'folder',
    ]);
    expect(mediaRepository.requests.first.argument, query);
    expect(mediaRepository.requests.last.argument, '/album');
    await container
        .read(folderMediaPaginatedProvider('/album').notifier)
        .loadMore();
    expect(mediaRepository.requests.last.pageIndex, 1);
    expect(warmups.every((warmup) => warmup.limit == 16), isTrue);
  });

  test('content-kind OCR search trims input and refreshes page zero', () async {
    final provider = contentKindPaginatedProvider(MediaContentKind.document);
    container.listen(provider, (_, _) {});
    await flushLoads();
    final notifier = container.read(provider.notifier);
    expect(mediaRepository.requests.single.argument, MediaContentKind.document);
    expect(mediaRepository.requests.single.ocrQuery, isNull);
    await notifier.setOcrQuery('  receipt  ');
    expect(mediaRepository.requests.last.ocrQuery, 'receipt');
    expect(mediaRepository.requests.last.pageIndex, 0);
    await notifier.setOcrQuery('   ');
    expect(mediaRepository.requests.last.ocrQuery, isNull);
    expect(container.read(provider).items.length, 1);
  });
}
