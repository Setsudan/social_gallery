import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/album_cover_tile.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openAlbum(FolderInfo folder) {
    context.push(folderProfileLocation(folder.path));
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context, ref);
    final foldersAsync = ref.watch(allFoldersProvider);

    listenForTabScrollToTop(
      ref,
      kShellTabExplore,
      _scrollController,
      motion: motion,
    );

    ref.listen<bool>(syncStateProvider, (previous, current) {
      if (previous == true && current == false) {
        ref.invalidate(allFoldersProvider);
      }
    });

    return Scaffold(
      extendBody: true,
      body: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load albums',
          message: error.toString(),
        ),
        data: (folders) {
          final albums = folders.where((folder) => folder.mediaCount > 0).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          if (albums.isEmpty) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(child: OneUiPageHeader(title: 'Albums')),
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.photo_album_outlined,
                    title: 'No albums yet',
                    message: 'Sync your library to see albums from your device.',
                  ),
                ),
              ],
            );
          }

          const columns = 3;
          final padding = FloatingNavInsets.scrollPadding(context).add(
            const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              0,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.md,
            ),
          );

          return CustomScrollView(
            controller: _scrollController,
            cacheExtent: 600,
            slivers: [
              const SliverToBoxAdapter(child: OneUiPageHeader(title: 'Albums')),
              SliverPadding(
                padding: padding,
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                        playOnceKey: 'album_${folder.path}',
                        child: AlbumCoverTile(
                          title: folder.name,
                          coverUri: folder.displayCoverUri,
                          locked: folder.isLockedAccount,
                          itemCount: folder.mediaCount,
                          onTap: () => _openAlbum(folder),
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
