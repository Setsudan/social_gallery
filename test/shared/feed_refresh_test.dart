import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/app/providers/data_providers.dart';
import 'package:social_gallery/app/providers/feed_refresh_providers.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/domain/models/feed_item.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';
import 'package:social_gallery/domain/models/follow_status.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/home/home_providers.dart';
import 'package:social_gallery/shared/pagination/media_pagination_providers.dart';

class _MediaRepository extends Fake implements MediaRepository {
  int homeLoads = 0;
  int galleryLoads = 0;
  int favoriteLoads = 0;
  int storyLoads = 0;

  @override
  Future<List<FeedItem>> getHomeFeedPage(int page) async {
    homeLoads++;
    return [];
  }

  @override
  Future<List<MediaItem>> getGalleryMediaPage(int page) async {
    galleryLoads++;
    return [];
  }

  @override
  Future<List<MediaItem>> getFavoritesPage(int page) async {
    favoriteLoads++;
    return [];
  }

  @override
  Future<List<FolderWithStories>> getFoldersWithStories() async {
    storyLoads++;
    return [];
  }
}

void main() {
  FolderInfo folder({
    String path = '/album',
    String name = 'Album',
    int mediaCount = 1,
    FollowStatus followStatus = FollowStatus.homeFeed,
    bool isBiometricLocked = false,
    bool showInStories = true,
  }) => FolderInfo(
    path: path,
    name: name,
    mediaCount: mediaCount,
    followStatus: followStatus,
    isBiometricLocked: isBiometricLocked,
    showInStories: showInStories,
  );

  test('eligibility signature ignores ordering, names, and media counts', () {
    final originalFolders = [folder(), folder(path: '/other')];
    final changedFolders = [
      folder(path: '/other', name: 'Renamed', mediaCount: 50),
      folder(mediaCount: 10),
    ];
    expect(
      folderFeedEligibilitySignature(originalFolders),
      folderFeedEligibilitySignature(changedFolders),
    );
    for (final changedFolder in [
      folder(followStatus: FollowStatus.accountOnly),
      folder(isBiometricLocked: true),
      folder(showInStories: false),
    ]) {
      expect(
        folderFeedEligibilitySignature([folder()]),
        isNot(folderFeedEligibilitySignature([changedFolder])),
      );
    }
  });

  testWidgets(
    'widget refresh leaves inactive pagination providers uninitialized',
    (tester) async {
      final mediaRepository = _MediaRepository();
      final container = ProviderContainer(
        overrides: [mediaRepositoryProvider.overrideWithValue(mediaRepository)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                return TextButton(
                  onPressed: () => refreshFeedProviders(ref),
                  child: const Text('Refresh'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Refresh'));
      await tester.pump();
      expect(container.exists(homeFeedPaginatedProvider), isFalse);
      expect(container.exists(galleryPaginatedProvider), isFalse);
      expect(container.exists(favoritesPaginatedProvider), isFalse);
      expect(mediaRepository.homeLoads, 0);
      expect(mediaRepository.galleryLoads, 0);
      expect(mediaRepository.favoriteLoads, 0);
    },
  );

  testWidgets('widget refresh reloads active lists and invalidates stories', (
    tester,
  ) async {
    final mediaRepository = _MediaRepository();
    final container = ProviderContainer(
      overrides: [mediaRepositoryProvider.overrideWithValue(mediaRepository)],
    );
    addTearDown(container.dispose);
    final homeSubscription = container.listen(
      homeFeedPaginatedProvider,
      (_, _) {},
    );
    final gallerySubscription = container.listen(
      galleryPaginatedProvider,
      (_, _) {},
    );
    final favoritesSubscription = container.listen(
      favoritesPaginatedProvider,
      (_, _) {},
    );
    final storiesSubscription = container.listen(
      homeStoriesProvider,
      (_, _) {},
    );
    addTearDown(homeSubscription.close);
    addTearDown(gallerySubscription.close);
    addTearDown(favoritesSubscription.close);
    addTearDown(storiesSubscription.close);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              return TextButton(
                onPressed: () => refreshFeedProviders(ref),
                child: const Text('Refresh'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(mediaRepository.homeLoads, 1);
    expect(mediaRepository.galleryLoads, 1);
    expect(mediaRepository.favoriteLoads, 1);
    expect(mediaRepository.storyLoads, 1);

    await tester.tap(find.text('Refresh'));
    await tester.pump();
    expect(mediaRepository.homeLoads, 2);
    expect(mediaRepository.galleryLoads, 2);
    expect(mediaRepository.favoriteLoads, 2);
    expect(mediaRepository.storyLoads, 2);
  });

  testWidgets(
    'visibility changes debounce and disposal cancels scheduled refresh',
    (tester) async {
      final mediaRepository = _MediaRepository();
      final folders = StreamController<List<FolderInfo>>();
      final container = ProviderContainer(
        overrides: [
          mediaRepositoryProvider.overrideWithValue(mediaRepository),
          allFoldersProvider.overrideWith((ref) => folders.stream),
        ],
      );
      container.read(feedRefreshCoordinatorProvider);
      container.listen(homeFeedPaginatedProvider, (_, _) {});
      await tester.pump();
      folders.add([folder()]);
      await tester.pump();
      folders.add([folder(showInStories: false)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      folders.add([folder(followStatus: FollowStatus.accountOnly)]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(mediaRepository.homeLoads, 1);
      await tester.pump(const Duration(milliseconds: 100));
      expect(mediaRepository.homeLoads, 2);

      folders.add([folder()]);
      await tester.pump();
      final closingFolders = folders.close();
      await tester.pump();
      await closingFolders;
      container.dispose();
      await tester.pump(const Duration(milliseconds: 300));
      expect(mediaRepository.homeLoads, 2);
    },
  );
}
