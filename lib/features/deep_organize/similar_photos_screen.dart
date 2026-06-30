import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class SimilarPhotosScreen extends ConsumerWidget {
  const SimilarPhotosScreen({super.key});

  Future<void> _deleteOthers(
    WidgetRef ref,
    BuildContext context,
    List<MediaItem> group,
  ) async {
    final keepBest = ref.read(suggestKeepBestProvider);
    final keeper = keepBest(group);
    final toDelete = group.where((i) => i.id != keeper.id).toList();
    if (toDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete similar photos'),
        content: Text(
          'Keep "${keeper.displayName}" and delete ${toDelete.length} similar items?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(mediaRepositoryProvider).deleteFromDevice(toDelete);
      invalidateAnalysisProviders(ref);
      refreshFeedProviders(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(similarPhotoGroupsProvider);

    return groupsAsync.when(
      loading: () => OneUiSubpageScaffold(
        title: 'Similar photos',
        isLoading: true,
        body: const SizedBox.shrink(),
      ),
      error: (e, _) => OneUiSubpageScaffold(
        title: 'Similar photos',
        error: e,
        body: const SizedBox.shrink(),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return OneUiSubpageScaffold(
            title: 'Similar photos',
            subtitle: 'Run a scan from Deep organize first.',
            isEmpty: true,
            empty: const EmptyState(
              title: 'No similar groups found',
              icon: Icons.compare,
            ),
            body: const SizedBox.shrink(),
          );
        }

        return OneUiSubpageScaffold(
          title: 'Similar photos',
          subtitle: 'Pick the best shot and remove near-duplicates.',
          padding: const EdgeInsets.all(16),
          body: ListView.separated(
            itemCount: groups.length,
            separatorBuilder: (_, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('${group.length} similar items'),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: group.length,
                          separatorBuilder: (_, i) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final item = group[i];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 100,
                                child: MediaThumbnail(assetId: item.uri),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => _deleteOthers(ref, context, group),
                        child: const Text('Keep best, delete others'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
