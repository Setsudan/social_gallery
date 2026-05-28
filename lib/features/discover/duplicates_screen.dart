import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/domain/models/duplicate_group.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class DuplicatesScreen extends ConsumerStatefulWidget {
  const DuplicatesScreen({super.key});

  @override
  ConsumerState<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends ConsumerState<DuplicatesScreen> {
  List<DuplicateGroup> _groups = [];
  DuplicateGroup? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final candidates = await ref
        .read(mediaRepositoryProvider)
        .getPotentialDuplicates();
    final groups = ref.read(findDuplicateGroupsProvider)(candidates);
    setState(() {
      _groups = groups;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selected == null
          ? _buildGroupList()
          : _buildGroupDetail(),
    );
  }

  Widget _buildGroupList() {
    if (_groups.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OneUiPageHeader(title: 'Duplicates'),
          Expanded(child: Center(child: Text('No duplicate groups found.'))),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _groups.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const OneUiPageHeader(
            title: 'Duplicates',
            subtitle: 'Groups of similar photos by size and dimensions.',
          );
        }
        final group = _groups[index - 1];
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
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
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
        ),
      ],
    );
  }
}
