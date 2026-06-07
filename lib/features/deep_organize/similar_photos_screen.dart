import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class SimilarPhotosScreen extends ConsumerStatefulWidget {
  const SimilarPhotosScreen({super.key});

  @override
  ConsumerState<SimilarPhotosScreen> createState() =>
      _SimilarPhotosScreenState();
}

class _SimilarPhotosScreenState extends ConsumerState<SimilarPhotosScreen> {
  bool _loading = true;
  List<List<MediaItem>> _groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final mediaRepo = ref.read(mediaRepositoryProvider);
    final analysisRepo = ref.read(mediaAnalysisRepositoryProvider);
    final findSimilar = ref.read(findSimilarGroupsProvider);

    final items = await mediaRepo.getAllHomeFeedMedia();
    final analysis = await analysisRepo.getAllCached();
    final groups = findSimilar(items: items, analysisById: analysis);
    final byId = {for (final i in items) i.id: i};

    setState(() {
      _groups = groups
          .map(
            (g) => g.mediaIds
                .map((id) => byId[id])
                .whereType<MediaItem>()
                .toList(),
          )
          .where((g) => g.length > 1)
          .toList();
      _loading = false;
    });
  }

  Future<void> _deleteOthers(List<MediaItem> group) async {
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
      await _load();
      ref.invalidate(discoverHubProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OneUiPageHeader(
                  title: 'Similar photos',
                  subtitle: 'Run a scan from Deep organize first.',
                ),
                Expanded(
                  child: Center(child: Text('No similar groups found.')),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groups.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const OneUiPageHeader(
                    title: 'Similar photos',
                    subtitle: 'Pick the best shot and remove near-duplicates.',
                  );
                }
                final group = _groups[index - 1];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
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
                          onPressed: () => _deleteOthers(group),
                          child: const Text('Keep best, delete others'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
