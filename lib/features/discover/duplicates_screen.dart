import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/layout/responsive_grid.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class DuplicatesScreen extends ConsumerStatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  ConsumerState<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends ConsumerState<DuplicatesScreen> {
  DuplicateGroup? _selected;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(duplicateGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selected == null ? null : const Text('Duplicate group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_selected != null) {
              setState(() => _selected = null);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => OneUiSubpageScaffold(
          title: 'Duplicates',
          error: e,
          body: const SizedBox.shrink(),
        ),
        data: (groups) => _selected == null
            ? _buildGroupList(groups)
            : _buildGroupDetail(),
      ),
    );
  }

  Widget _buildGroupList(List<DuplicateGroup> groups) {
    if (groups.isEmpty) {
      return OneUiSubpageScaffold(
        title: 'Duplicates',
        isEmpty: true,
        empty: const EmptyState(
          title: 'No duplicate groups found',
          message: 'Your library looks clean based on file size and dimensions.',
          icon: Icons.check_circle_outline,
        ),
        body: const SizedBox.shrink(),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: groups.length + 1,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const OneUiPageHeader(
            title: 'Duplicates',
            subtitle: 'Groups of similar photos by size and dimensions.',
          );
        }
        final group = groups[index - 1];
        final cover = group.items.first;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => _selected = group),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MediaThumbnail(assetId: cover.uri),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('${group.count} similar items'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupDetail() {
    final group = _selected!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () => context.push(duplicateReviewLocation(group.key)),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Keep best and review'),
          ),
        ),
        Builder(
          builder: (context) {
            final columns = gridCrossAxisCountForWidth(
              MediaQuery.sizeOf(context).width,
            );

            return Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: group.items.length,
                itemBuilder: (context, index) {
                  final media = group.items[index];
                  return GestureDetector(
                    onTap: () => context.push(
                      mediaViewerLocation(
                        media.uri,
                        mediaId: media.id,
                        favorite: media.isFavorite,
                      ),
                    ),
                    child: MediaThumbnail(
                      assetId: media.uri,
                      showVideoBadge: media.isVideo,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
