import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/cache/cache_service.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/animation/modal_sheet.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/core/utils/media_hero.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/fullscreen_media_content.dart';
import 'package:social_gallery/shared/widgets/post_metadata_sheet.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.mediaId,
    required this.assetId,
    this.initialFavorite = false,
  });

  final int mediaId;
  final String assetId;
  final bool initialFavorite;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late bool _favorite;
  MediaItem? _media;
  bool _loading = true;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _favorite = widget.initialFavorite;
    _load();
  }

  Future<void> _load() async {
    final item = await ref
        .read(mediaRepositoryProvider)
        .getMediaById(widget.mediaId);
    if (!mounted) return;
    setState(() {
      _media = item;
      if (item != null) _favorite = item.isFavorite;
      _loading = false;
    });
  }

  Future<void> _toggleFavorite() async {
    AppHaptics.light();
    final next = !_favorite;
    await ref.read(mediaRepositoryProvider).setFavorite(widget.mediaId, next);
    setState(() => _favorite = next);
  }

  Future<void> _share() async {
    final entity = await AssetEntity.fromId(widget.assetId);
    if (entity == null) return;
    final file = await entity.file;
    if (file == null || !await file.exists()) return;
    await Share.shareXFiles([XFile(file.path)], text: _media?.displayName);
  }

  Future<void> _moveToTrash() async {
    final media = _media;
    if (media == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to trash'),
        content: const Text(
          'This item will be moved to trash and can be restored from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Move to trash'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(mediaRepositoryProvider).trashMedia([media]);
    if (mounted) {
      AppHaptics.success();
      context.pop();
    }
  }

  void _showMetadata() {
    final media = _media;
    if (media == null) return;
    showAppModalBottomSheet<void>(
      context: context,
      ref: ref,
      builder: (context) => PostMetadataSheet(
        media: media,
        fileSizeLabel: CacheService.formatBytes(media.size),
      ),
    );
  }

  void _openFolder() {
    final media = _media;
    if (media == null) return;
    context.push(folderProfileLocation(media.folderPath));
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context, ref);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          duration: motion.fade,
          opacity: _showChrome ? 1 : 0,
          child: AppBar(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Details',
                onPressed: _showMetadata,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: _share,
              ),
              IconButton(
                icon: Icon(
                  _favorite ? Icons.favorite : Icons.favorite_border,
                  color: _favorite ? Colors.red : Colors.white,
                ),
                tooltip: 'Favorite',
                onPressed: _toggleFavorite,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  switch (value) {
                    case 'folder':
                      _openFolder();
                    case 'trash':
                      _moveToTrash();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'folder',
                    child: ListTile(
                      leading: Icon(Icons.folder_outlined),
                      title: Text('Open folder'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'trash',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Move to trash'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => setState(() => _showChrome = !_showChrome),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _buildBody(),
      ),
      bottomNavigationBar: _media != null
          ? AnimatedSlide(
              duration: motion.fade,
              curve: motion.enterCurve,
              offset: _showChrome ? Offset.zero : const Offset(0, 1),
              child: AnimatedOpacity(
                duration: motion.fade,
                opacity: _showChrome ? 1 : 0,
                child: Material(
                  color: Colors.black87,
                  child: SafeArea(
                    top: false,
                    child: ListTile(
                      leading: const Icon(
                        Icons.folder_outlined,
                        color: Colors.white70,
                      ),
                      title: Text(
                        _media!.folderName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _media!.displayName,
                        style: const TextStyle(color: Colors.white54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.info_outline,
                          color: Colors.white70,
                        ),
                        onPressed: _showMetadata,
                      ),
                      onTap: _openFolder,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    return FutureBuilder<AssetEntity?>(
      future: AssetEntity.fromId(widget.assetId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final entity = snapshot.data;
        if (entity == null) {
          return const Center(
            child: Text(
              'Media not found',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return FullscreenMediaContent(
          entity: entity,
          heroTag: mediaHeroTag(widget.mediaId),
          videoFit: BoxFit.contain,
          imageFit: BoxFit.contain,
        );
      },
    );
  }
}
