import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/shared/widgets/album_cover_tile.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class LockedAlbumsScreen extends ConsumerWidget {
  const LockedAlbumsScreen({super.key});

  void _openAlbum(BuildContext context, FolderInfo folder) {
    context.push(folderProfileLocation(folder.path));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final foldersAsync = ref.watch(allFoldersProvider);

    ref.listen<bool>(syncStateProvider, (previous, current) {
      if (previous == true && current == false) {
        ref.invalidate(allFoldersProvider);
      }
    });

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.light();
            context.pop();
          },
        ),
      ),
      body: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.albumsErrorLoad,
          message: error.toString(),
        ),
        data: (folders) {
          final albums = folders
              .where(
                (folder) =>
                    folder.mediaCount > 0 && folder.isLockedAccount,
              )
              .toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          if (albums.isEmpty) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: OneUiPageHeader(title: l10n.lockedAlbumsTitle),
                ),
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.lock_outline,
                    title: l10n.lockedAlbumsEmptyTitle,
                    message: l10n.lockedAlbumsEmptyMessage,
                  ),
                ),
              ],
            );
          }

          const columns = 3;
          const padding = EdgeInsets.fromLTRB(
            OneUiSpacing.pageHorizontal,
            0,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.md,
          );

          return CustomScrollView(
            cacheExtent: 600,
            slivers: [
              SliverToBoxAdapter(
                child: OneUiPageHeader(title: l10n.lockedAlbumsTitle),
              ),
              SliverPadding(
                padding: padding,
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: OneUiSpacing.sm,
                    mainAxisSpacing: OneUiSpacing.sm,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final folder = albums[index];
                      return StaggeredEntrance(
                        index: index,
                        playOnceKey: 'locked_album_${folder.path}',
                        child: AlbumCoverTile(
                          title: folder.name,
                          coverUri: folder.displayCoverUri,
                          locked: true,
                          itemCount: folder.mediaCount,
                          onTap: () => _openAlbum(context, folder),
                        ),
                      );
                    },
                    childCount: albums.length,
                    addRepaintBoundaries: true,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
