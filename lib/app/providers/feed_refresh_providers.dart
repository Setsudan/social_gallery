import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers/data_providers.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/features/home/home_providers.dart';
import 'package:social_gallery/shared/pagination/media_pagination_providers.dart';

const _feedRefreshDebounce = Duration(milliseconds: 300);

/// Stable signature of folder visibility fields that affect feed eligibility.
String folderFeedEligibilitySignature(List<FolderInfo> folders) {
  final sorted = [...folders]..sort((a, b) => a.path.compareTo(b.path));
  return sorted
      .map(
        (folder) =>
            '${folder.path}:${folder.followStatus.storageValue}:${folder.isBiometricLocked}:${folder.showInStories}',
      )
      .join('|');
}

/// Debounced listener that refreshes feeds when folder visibility changes.
final feedRefreshCoordinatorProvider = Provider<void>((ref) {
  Timer? debounce;

  ref.onDispose(() => debounce?.cancel());

  ref.listen<AsyncValue<List<FolderInfo>>>(allFoldersProvider, (
    previous,
    next,
  ) {
    final previousFolders = previous?.valueOrNull;
    final nextFolders = next.valueOrNull;
    if (previousFolders == null || nextFolders == null) return;

    if (folderFeedEligibilitySignature(previousFolders) ==
        folderFeedEligibilitySignature(nextFolders)) {
      return;
    }

    debounce?.cancel();
    debounce = Timer(_feedRefreshDebounce, () {
      refreshFeedProvidersFromRef(ref);
    });
  });
});

/// Refreshes home feed, gallery, explore, stories, and folder grids.
void refreshFeedProvidersFromRef(Ref ref) {
  _refreshFeedTargets(ref.exists, ref.read, ref.invalidate);
}

/// Widget-side alias for [refreshFeedProvidersFromRef].
void refreshFeedProviders(WidgetRef ref) {
  _refreshFeedTargets(ref.exists, ref.read, ref.invalidate);
}

/// Reloads existing lists in place and invalidates other feed targets.
void _refreshFeedTargets(
  bool Function(ProviderBase<Object?> provider) exists,
  T Function<T>(ProviderListenable<T> provider) read,
  void Function(ProviderOrFamily provider) invalidate,
) {
  if (exists(homeFeedPaginatedProvider)) {
    unawaited(read(homeFeedPaginatedProvider.notifier).loadMore(refresh: true));
  } else {
    invalidate(homeFeedPaginatedProvider);
  }

  if (exists(galleryPaginatedProvider)) {
    unawaited(read(galleryPaginatedProvider.notifier).loadMore(refresh: true));
  } else {
    invalidate(galleryPaginatedProvider);
  }

  invalidate(explorePaginatedProvider);
  invalidate(homeStoriesProvider);
  invalidate(folderMediaPaginatedProvider);

  if (exists(favoritesPaginatedProvider)) {
    unawaited(
      read(favoritesPaginatedProvider.notifier).loadMore(refresh: true),
    );
  } else {
    invalidate(favoritesPaginatedProvider);
  }
}
