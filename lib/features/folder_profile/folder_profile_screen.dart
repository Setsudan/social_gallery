import 'package:flutter/material.dart';



import 'package:flutter_riverpod/flutter_riverpod.dart';



import 'package:social_gallery/app/providers.dart';

import 'package:social_gallery/core/auth/folder_access.dart';

import 'package:social_gallery/core/auth/folder_unlock_store.dart';

import 'package:social_gallery/core/l10n/l10n_extensions.dart';

import 'package:social_gallery/shared/navigation/media_viewer_session.dart';

import 'package:social_gallery/core/utils/haptics.dart';

import 'package:social_gallery/domain/models/folder_info.dart';

import 'package:social_gallery/domain/models/follow_status.dart';

import 'package:social_gallery/domain/models/media_item.dart';

import 'package:social_gallery/shared/widgets/album_cover_picker_sheet.dart';

import 'package:social_gallery/shared/widgets/empty_state.dart';

import 'package:social_gallery/shared/widgets/folder_avatar.dart';

import 'package:social_gallery/shared/widgets/folder_lock_gate.dart';

import 'package:social_gallery/features/folder_profile/folder_profile_providers.dart';

import 'package:social_gallery/shared/media/media_bulk_actions.dart';

import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';

import 'package:social_gallery/core/theme/one_ui_theme.dart';

import 'package:social_gallery/shared/widgets/media_grid.dart';

import 'package:social_gallery/shared/widgets/media_selection_app_bar.dart';

import 'package:social_gallery/l10n/app_localizations.dart';



class FolderProfileScreen extends ConsumerStatefulWidget {

  const FolderProfileScreen({super.key, required this.folderPath});



  final String folderPath;



  @override

  ConsumerState<FolderProfileScreen> createState() =>

      _FolderProfileScreenState();

}



class _FolderProfileScreenState extends ConsumerState<FolderProfileScreen> {

  FolderUnlockStore? _unlockStore;

  final Set<int> _selectedIds = {};



  void _toggleSelect(MediaItem item) {

    AppHaptics.medium();

    setState(() {

      if (_selectedIds.contains(item.id)) {

        _selectedIds.remove(item.id);

      } else {

        _selectedIds.add(item.id);

      }

    });

  }



  void _startSelection(MediaItem item) {

    AppHaptics.medium();

    setState(() {

      _selectedIds.add(item.id);

    });

  }



  void _clearSelection() => setState(_selectedIds.clear);



  Future<void> _bulkDelete() => bulkTrash(

        ref,

        context,

        _selectedIds,

        onDone: _clearSelection,

        useHaptics: true,

      );



  Future<void> _bulkMove() => bulkMove(

        ref,

        context,

        _selectedIds,

        excludePaths: {widget.folderPath},

        onDone: _clearSelection,

        useHaptics: true,

      );



  Future<void> _bulkFavorite(bool favorite) => bulkFavorite(

        ref,

        _selectedIds,

        favorite,

        onDone: _clearSelection,

        useHaptics: true,

      );



  Future<void> _handleMenuAction(

    FolderInfo folder,

    _FolderProfileMenuAction action,

  ) async {

    AppHaptics.medium();



    switch (action) {

      case _FolderProfileMenuAction.changeCover:

        final unlocked = await ensureFolderUnlocked(ref: ref, folder: folder);

        if (!unlocked || !mounted) return;

        await _changeAlbumCover(folder);

      case _FolderProfileMenuAction.resetCover:

        final unlocked = await ensureFolderUnlocked(ref: ref, folder: folder);

        if (!unlocked || !mounted) return;

        await _resetAlbumCover(folder);

      case _FolderProfileMenuAction.visibility:

        await _showFollowDialog(folder);

    }

  }



  Future<void> _changeAlbumCover(FolderInfo folder) async {

    final selectedUri = await showAlbumCoverPickerSheet(

      context: context,

      ref: ref,

      folder: folder,

    );

    if (selectedUri == null || !mounted) return;



    AppHaptics.success();

    await ref

        .read(folderRepositoryProvider)

        .setCustomCover(folder.path, selectedUri);

    ref.invalidate(folderProvider(folder.path));

    ref.invalidate(allFoldersProvider);

  }



  Future<void> _resetAlbumCover(FolderInfo folder) async {

    AppHaptics.success();

    await ref.read(folderRepositoryProvider).setCustomCover(folder.path, null);

    ref.invalidate(folderProvider(folder.path));

    ref.invalidate(allFoldersProvider);

  }



  Future<void> _setAlbumCover() async {

    if (_selectedIds.length != 1) return;

    final items = await ref.read(folderMediaProvider(widget.folderPath).future);

    final id = _selectedIds.first;

    MediaItem? selected;

    for (final item in items) {

      if (item.id == id) {

        selected = item;

        break;

      }

    }

    if (selected == null) return;



    AppHaptics.success();

    await ref

        .read(folderRepositoryProvider)

        .setCustomCover(widget.folderPath, selected.uri);

    ref.invalidate(folderProvider(widget.folderPath));

    ref.invalidate(allFoldersProvider);

    _clearSelection();

  }



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    _unlockStore = ref.read(folderUnlockStoreProvider);

  }



  @override

  void dispose() {

    _unlockStore?.lock(widget.folderPath);

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final l10n = context.l10n;

    final folderAsync = ref.watch(folderProvider(widget.folderPath));

    final inSelectionMode = _selectedIds.isNotEmpty;



    return folderAsync.when(

      data: (folder) {

        if (folder == null) {

          return Scaffold(

            appBar: AppBar(),

            body: EmptyState(title: l10n.errorFolderNotFound),

          );

        }



        final PreferredSizeWidget appBar = inSelectionMode

            ? MediaSelectionAppBar(

                selectedCount: _selectedIds.length,

                onCancel: _clearSelection,

                onFavorite: () => _bulkFavorite(true),

                onUnfavorite: () => _bulkFavorite(false),

                onMove: _bulkMove,

                onTrash: _bulkDelete,

                onSetAlbumCover:

                    _selectedIds.length == 1 ? _setAlbumCover : null,

              )

            : AppBar(

                actions: [

                  PopupMenuButton<_FolderProfileMenuAction>(

                    tooltip: l10n.tooltipAlbumOptions,

                    onSelected: (action) => _handleMenuAction(folder, action),

                    itemBuilder: (context) {

                      final hasCustomCover =

                          folder.customCoverUri?.trim().isNotEmpty == true;



                      return [

                        PopupMenuItem(

                          value: _FolderProfileMenuAction.changeCover,

                          child: ListTile(

                            leading: const Icon(Icons.image_outlined),

                            title: Text(l10n.folderChangeCover),

                            contentPadding: EdgeInsets.zero,

                            dense: true,

                          ),

                        ),

                        if (hasCustomCover)

                          PopupMenuItem(

                            value: _FolderProfileMenuAction.resetCover,

                            child: ListTile(

                              leading: const Icon(Icons.restore_outlined),

                              title: Text(l10n.folderUseLatestPhoto),

                              contentPadding: EdgeInsets.zero,

                              dense: true,

                            ),

                          ),

                        PopupMenuItem(

                          value: _FolderProfileMenuAction.visibility,

                          child: ListTile(

                            leading: const Icon(Icons.visibility_outlined),

                            title: Text(l10n.folderVisibilityTitle),

                            contentPadding: EdgeInsets.zero,

                            dense: true,

                          ),

                        ),

                      ];

                    },

                  ),

                ],

              );



        return Scaffold(

          appBar: appBar,

          body: Column(

            children: [

              _header(folder, l10n),

              Expanded(

                child: FolderLockGate(

                  folder: folder,

                  builder: (context) => ref

                      .watch(folderMediaProvider(folder.path))

                      .when(

                        data: (items) {

                          if (items.isEmpty) {

                            return EmptyState(title: l10n.folderNoMedia);

                          }

                          return MediaGrid(

                            items: items,

                            selectedIds: _selectedIds,

                            onSelectToggle: _toggleSelect,

                            onLongPress: _startSelection,

                            onTap: (item) => openMediaViewer(

                              context,

                              ref,

                              items: items,

                              item: item,

                            ),

                          );

                        },

                        loading: () =>

                            const Center(child: CircularProgressIndicator()),

                        error: (e, _) => EmptyState(

                          title: l10n.errorGeneric,

                          message: e.toString(),

                        ),

                      ),

                ),

              ),

            ],

          ),

        );

      },

      loading: () =>

          const Scaffold(body: Center(child: CircularProgressIndicator())),

      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),

    );

  }



  Widget _header(FolderInfo folder, AppLocalizations l10n) {

    return Padding(

      padding: const EdgeInsets.fromLTRB(

        OneUiSpacing.pageHorizontal,

        OneUiSpacing.md,

        OneUiSpacing.pageHorizontal,

        OneUiSpacing.sm,

      ),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          FolderAvatar(

            name: folder.name,

            size: 72,

            coverUri: folder.isLockedAccount ? null : folder.displayCoverUri,

            locked: folder.isLockedAccount,

          ),

          const SizedBox(width: 16),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  folder.name,

                  style: Theme.of(context).textTheme.headlineMedium,

                ),

                Text(l10n.folderItemCount(folder.mediaCount)),

                const SizedBox(height: 8),

                GestureDetector(

                  onTap: () => _editBio(folder),

                  child: Text(

                    folder.biography?.isNotEmpty == true

                        ? folder.biography!

                        : l10n.folderAddBiography,

                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(

                      color: Theme.of(context).colorScheme.primary,

                    ),

                  ),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Future<void> _editBio(FolderInfo folder) async {

    final l10n = context.l10n;

    final controller = TextEditingController(text: folder.biography ?? '');



    final saved = await showDialog<String>(

      context: context,

      builder: (context) => AlertDialog(

        title: Text(l10n.folderBiographyTitle),

        content: TextField(controller: controller, maxLines: 4),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context),

            child: Text(l10n.actionCancel),

          ),

          FilledButton(

            onPressed: () => Navigator.pop(context, controller.text.trim()),

            child: Text(l10n.actionSave),

          ),

        ],

      ),

    );



    if (saved != null) {

      await ref

          .read(folderRepositoryProvider)

          .updateFollowStatus(

            folder.path,

            folder.followStatus,

            isBiometricLocked: folder.isBiometricLocked,

            biography: saved,

          );

    }

  }



  Future<void> _showFollowDialog(FolderInfo folder) async {

    final l10n = context.l10n;

    var choice = _visibilityChoice(

      folder.followStatus,

      folder.isBiometricLocked,

    );



    await showDialog<void>(

      context: context,

      builder: (context) {

        return StatefulBuilder(

          builder: (context, setDialogState) {

            return AlertDialog(

              title: Text(l10n.folderVisibilityTitle),

              content: RadioGroup<_FolderVisibilityOption>(

                groupValue: choice,

                onChanged: (v) => setDialogState(() => choice = v!),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: _FolderVisibilityOption.values

                      .map(

                        (option) => ListTile(

                          title: Text(option.label(l10n)),

                          leading: Radio<_FolderVisibilityOption>(

                            value: option,

                          ),

                          onTap: () => setDialogState(() => choice = option),

                        ),

                      )

                      .toList(),

                ),

              ),

              actions: [

                TextButton(

                  onPressed: () => Navigator.pop(context),

                  child: Text(l10n.actionCancel),

                ),

                FilledButton(

                  onPressed: () async {

                    await ref

                        .read(folderRepositoryProvider)

                        .updateFollowStatus(

                          folder.path,

                          choice.status,

                          isBiometricLocked: choice.locked,

                        );



                    if (choice.locked) {

                      ref.read(folderUnlockStoreProvider).lock(folder.path);

                    }



                    ref.invalidate(folderProvider(folder.path));

                    refreshFeedProviders(ref);



                    if (context.mounted) Navigator.pop(context);

                  },

                  child: Text(l10n.actionSave),

                ),

              ],

            );

          },

        );

      },

    );

  }



  _FolderVisibilityOption _visibilityChoice(FollowStatus status, bool locked) {

    if (status == FollowStatus.homeFeed) {

      return _FolderVisibilityOption.homeFeed;

    }



    if (status == FollowStatus.unfollowed) {

      return _FolderVisibilityOption.hidden;

    }



    return locked

        ? _FolderVisibilityOption.accountLocked

        : _FolderVisibilityOption.accountOnly;

  }

}



enum _FolderProfileMenuAction {

  changeCover,

  resetCover,

  visibility,

}



enum _FolderVisibilityOption {

  homeFeed(FollowStatus.homeFeed, false),

  accountOnly(FollowStatus.accountOnly, false),

  accountLocked(FollowStatus.accountOnly, true),

  hidden(FollowStatus.unfollowed, false);



  const _FolderVisibilityOption(this.status, this.locked);



  final FollowStatus status;

  final bool locked;



  String label(AppLocalizations l10n) => switch (this) {

        homeFeed => l10n.folderVisibilityHomeFeed,

        accountOnly => l10n.folderVisibilityAccountOnly,

        accountLocked => l10n.folderVisibilityAccountLocked,

        hidden => l10n.folderVisibilityHidden,

      };

}


