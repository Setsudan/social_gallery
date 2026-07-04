import 'dart:io';



import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:photo_manager/photo_manager.dart';

import 'package:share_plus/share_plus.dart';

import 'package:social_gallery/app/providers.dart';

import 'package:social_gallery/app/router.dart';

import 'package:social_gallery/core/cache/cache_service.dart';

import 'package:social_gallery/core/l10n/l10n_extensions.dart';

import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';

import 'package:social_gallery/core/platform/reveal_in_file_explorer.dart';

import 'package:social_gallery/core/animation/app_motion.dart';

import 'package:social_gallery/core/animation/modal_sheet.dart';

import 'package:social_gallery/core/utils/haptics.dart';

import 'package:social_gallery/core/utils/media_hero.dart';

import 'package:social_gallery/domain/models/media_item.dart';

import 'package:social_gallery/shared/navigation/media_viewer_session.dart';

import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';

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

  late final PageController _pageController;

  late final List<MediaItem> _items;

  late final int _initialIndex;



  int _currentIndex = 0;

  final Map<int, MediaItem?> _loadedById = {};

  final Map<int, bool> _favoriteById = {};

  bool _showChrome = true;



  int get _pageCount => _items.isNotEmpty ? _items.length : 1;



  MediaItem _itemAt(int index) {

    if (_items.isNotEmpty) {

      return _items[index];

    }

    return MediaItem(

      id: widget.mediaId,

      uri: widget.assetId,

      displayName: '',

      folderName: '',

      folderPath: '',

      dateAdded: 0,

      dateModified: 0,

      size: 0,

      mimeType: '',

      isFavorite: widget.initialFavorite,

    );

  }



  MediaItem get _currentItem => _itemAt(_currentIndex);



  MediaItem? get _loadedMedia => _loadedById[_currentItem.id];



  bool get _favorite =>

      _favoriteById[_currentItem.id] ?? _currentItem.isFavorite;



  @override

  void initState() {

    super.initState();

    final session = ref.read(mediaViewerSessionProvider);

    if (session != null && session.items.isNotEmpty) {

      _items = List<MediaItem>.of(session.items);

      _initialIndex = session.initialIndex.clamp(0, _items.length - 1);

    } else {

      _items = [];

      _initialIndex = 0;

    }

    _currentIndex = _initialIndex;

    _pageController = PageController(initialPage: _currentIndex);

    _favoriteById[_itemAt(_currentIndex).id] = widget.initialFavorite;

    _loadMediaForIndex(_currentIndex);



    Future.microtask(() {

      ref.read(mediaViewerSessionProvider.notifier).state = null;

    });

  }



  @override

  void dispose() {

    _pageController.dispose();

    super.dispose();

  }



  Future<void> _loadMediaForIndex(int index) async {

    final item = _itemAt(index);

    if (_loadedById.containsKey(item.id)) return;



    final loaded =

        await ref.read(mediaRepositoryProvider).getMediaById(item.id);

    if (!mounted) return;



    setState(() {

      _loadedById[item.id] = loaded;

      if (loaded != null) {

        _favoriteById.putIfAbsent(item.id, () => loaded.isFavorite);

      }

    });

  }



  void _onPageChanged(int index) {

    setState(() => _currentIndex = index);

    _loadMediaForIndex(index);

  }



  Future<void> _toggleFavorite() async {

    AppHaptics.light();

    final item = _currentItem;

    final next = !_favorite;

    await ref.read(mediaRepositoryProvider).setFavorite(item.id, next);

    setState(() => _favoriteById[item.id] = next);

  }



  Future<void> _share() async {

    final item = _currentItem;

    final media = _loadedMedia;

    if (usesFilesystemGallery) {

      final file = File(item.uri);

      if (file.existsSync()) {

        await Share.shareXFiles(

          [XFile(file.path)],

          text: media?.displayName ?? file.path.split(Platform.pathSeparator).last,

        );

      }

      return;

    }

    final entity = await AssetEntity.fromId(item.uri);

    if (entity == null) return;

    final file = await entity.file;

    if (file == null || !await file.exists()) return;

    await Share.shareXFiles(

      [XFile(file.path)],

      text: media?.displayName,

    );

  }



  Future<void> _moveToTrash() async {

    final l10n = context.l10n;

    final media = _loadedMedia ?? _currentItem;

    if (media.id == 0) return;



    final confirmed = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        title: Text(l10n.postMoveToTrash),

        content: Text(l10n.postMoveToTrashMessage),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context, false),

            child: Text(l10n.actionCancel),

          ),

          FilledButton(

            onPressed: () => Navigator.pop(context, true),

            child: Text(l10n.postMoveToTrash),

          ),

        ],

      ),

    );



    if (confirmed != true || !mounted) return;

    await ref.read(mediaRepositoryProvider).trashMedia([media]);

    refreshFeedProviders(ref);

    if (!mounted) return;



    AppHaptics.success();

    if (_pageCount <= 1) {

      context.pop();

      return;

    }



    setState(() {

      _items.removeAt(_currentIndex);

      _loadedById.remove(media.id);

      _favoriteById.remove(media.id);

    });



    if (_items.isEmpty) {

      context.pop();

      return;

    }



    final nextIndex = _currentIndex.clamp(0, _items.length - 1);

    _currentIndex = nextIndex;

    _pageController.jumpToPage(nextIndex);

    _loadMediaForIndex(nextIndex);

  }



  void _showMetadata() {

    final media = _loadedMedia;

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

    final media = _loadedMedia;

    if (media == null) return;

    context.push(folderProfileLocation(media.folderPath));

  }



  Future<void> _findInFileExplorer() async {

    final l10n = context.l10n;

    final item = _loadedMedia ?? _currentItem;

    final path = item.uri;

    if (path.isEmpty) return;

    final ok = await revealInFileExplorer(path);

    if (!mounted || ok) return;

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(content: Text(l10n.postFindInFileExplorerFailed)),

    );

  }



  @override

  Widget build(BuildContext context) {

    final l10n = context.l10n;

    final motion = AppMotion.of(context, ref);

    final media = _loadedMedia;

    final showPager = _pageCount > 1;



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

            title: showPager

                ? Text(

                    l10n.organizeProgress(_currentIndex + 1, _pageCount),

                    style: const TextStyle(

                      fontSize: 16,

                      fontWeight: FontWeight.w500,

                    ),

                  )

                : null,

            centerTitle: showPager,

            actions: [

              IconButton(

                icon: const Icon(Icons.info_outline),

                tooltip: l10n.tooltipDetails,

                onPressed: media == null ? null : _showMetadata,

              ),

              IconButton(

                icon: const Icon(Icons.share_outlined),

                tooltip: l10n.tooltipShare,

                onPressed: _share,

              ),

              IconButton(

                icon: Icon(

                  _favorite ? Icons.favorite : Icons.favorite_border,

                  color: _favorite ? Colors.red : Colors.white,

                ),

                tooltip: l10n.tooltipFavorite,

                onPressed: _toggleFavorite,

              ),

              PopupMenuButton<String>(

                icon: const Icon(Icons.more_vert, color: Colors.white),

                onSelected: (value) {

                  switch (value) {

                    case 'folder':

                      _openFolder();

                    case 'explorer':

                      _findInFileExplorer();

                    case 'trash':

                      _moveToTrash();

                  }

                },

                itemBuilder: (context) => [

                  PopupMenuItem(

                    value: 'folder',

                    child: ListTile(

                      leading: const Icon(Icons.folder_outlined),

                      title: Text(l10n.postOpenFolder),

                      contentPadding: EdgeInsets.zero,

                    ),

                  ),

                  if (usesFilesystemGallery)

                    PopupMenuItem(

                      value: 'explorer',

                      child: ListTile(

                        leading: const Icon(Icons.folder_open_outlined),

                        title: Text(l10n.postFindInFileExplorer),

                        contentPadding: EdgeInsets.zero,

                      ),

                    ),

                  PopupMenuItem(

                    value: 'trash',

                    child: ListTile(

                      leading: const Icon(Icons.delete_outline),

                      title: Text(l10n.postMoveToTrash),

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

        child: PageView.builder(

          controller: _pageController,

          itemCount: _pageCount,

          onPageChanged: _onPageChanged,

          physics: showPager

              ? const PageScrollPhysics()

              : const NeverScrollableScrollPhysics(),

          itemBuilder: (context, index) => _buildPage(index),

        ),

      ),

      bottomNavigationBar: media != null

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

                        media.folderName,

                        style: const TextStyle(color: Colors.white),

                      ),

                      subtitle: Text(

                        media.displayName,

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



  Widget _buildPage(int index) {

    final item = _itemAt(index);

    final heroTag =

        index == _initialIndex ? mediaHeroTag(item.id) : null;



    if (usesFilesystemGallery) {

      return FullscreenMediaContent(

        entity: null,

        assetPath: item.uri,

        heroTag: heroTag,

        videoFit: BoxFit.contain,

        imageFit: BoxFit.contain,

      );

    }



    return FutureBuilder<AssetEntity?>(

      future: AssetEntity.fromId(item.uri),

      builder: (context, snapshot) {

        if (snapshot.connectionState != ConnectionState.done) {

          return const Center(

            child: CircularProgressIndicator(color: Colors.white),

          );

        }



        final entity = snapshot.data;

        if (entity == null) {

          return Center(

            child: Text(

              context.l10n.errorMediaNotFound,

              style: const TextStyle(color: Colors.white),

            ),

          );

        }



        return FullscreenMediaContent(

          entity: entity,

          heroTag: heroTag,

          videoFit: BoxFit.contain,

          imageFit: BoxFit.contain,

        );

      },

    );

  }

}


