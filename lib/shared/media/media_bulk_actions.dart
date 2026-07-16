import 'dart:io';

import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/platform/image_clipboard.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/folder_picker_sheet.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';

Future<bool> confirmBulkTrashDialog(BuildContext context, int count) async {
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.bulkMoveToTrashTitle),
      content: Text(l10n.bulkMoveToTrashMessage(count)),
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
  return confirmed == true;
}

Future<List<MediaItem>> resolveSelectedMedia(
  WidgetRef ref,
  Set<int> selectedIds,
) {
  return ref.read(mediaRepositoryProvider).getMediaByIds(selectedIds);
}

Future<void> bulkTrash(
  WidgetRef ref,
  BuildContext context,
  Set<int> selectedIds, {
  VoidCallback? onDone,
  bool useHaptics = false,
}) async {
  if (selectedIds.isEmpty) return;
  final confirmed = await confirmBulkTrashDialog(context, selectedIds.length);
  if (!confirmed) return;

  if (useHaptics) AppHaptics.light();
  final items = await resolveSelectedMedia(ref, selectedIds);
  await ref.read(mediaRepositoryProvider).trashMedia(items);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.snackbarMovedToTrash(items.length))),
  );
  if (useHaptics) AppHaptics.success();
  refreshFeedProviders(ref);
  onDone?.call();
}

Future<void> bulkMove(
  WidgetRef ref,
  BuildContext context,
  Set<int> selectedIds, {
  Set<String>? excludePaths,
  VoidCallback? onDone,
  bool useHaptics = false,
}) async {
  if (selectedIds.isEmpty) return;

  final folders = await ref.read(folderRepositoryProvider).watchAll().first;
  if (!context.mounted) return;

  final targetPath = await showFolderPickerSheet(
    context: context,
    ref: ref,
    folders: folders,
    excludePaths: excludePaths ?? const [],
  );
  if (targetPath == null) return;

  if (useHaptics) AppHaptics.light();
  final items = await resolveSelectedMedia(ref, selectedIds);
  final moved =
      await ref.read(mediaRepositoryProvider).moveMedia(items, targetPath);
  if (!context.mounted) return;

  final l10n = context.l10n;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        moved == items.length
            ? l10n.snackbarMovedItems(moved)
            : moved == 0
                ? l10n.snackbarMoveFailed
                : l10n.snackbarMovedPartial(moved, items.length),
      ),
    ),
  );
  if (useHaptics) AppHaptics.success();
  refreshFeedProviders(ref);
  onDone?.call();
}

Future<void> bulkFavorite(
  WidgetRef ref,
  Set<int> selectedIds,
  bool favorite, {
  VoidCallback? onDone,
  bool useHaptics = false,
}) async {
  if (selectedIds.isEmpty) return;
  if (useHaptics) AppHaptics.light();
  final repo = ref.read(mediaRepositoryProvider);
  for (final id in selectedIds) {
    await repo.setFavorite(id, favorite);
  }
  if (useHaptics) AppHaptics.success();
  onDone?.call();
}

Future<void> createAlbumAndMove(
  WidgetRef ref,
  BuildContext context,
  Set<int> selectedIds, {
  VoidCallback? onDone,
}) async {
  if (selectedIds.isEmpty) return;

  final l10n = context.l10n;
  final nameController = TextEditingController();
  final albumName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.bulkCreateAlbumTitle),
      content: TextField(
        controller: nameController,
        decoration: InputDecoration(
          labelText: l10n.bulkAlbumNameLabel,
          border: const OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) Navigator.pop(context, name);
          },
          child: Text(l10n.bulkCreateAndMove),
        ),
      ],
    ),
  );

  if (albumName == null || albumName.isEmpty) return;

  final items = await resolveSelectedMedia(ref, selectedIds);
  final ok = await ref
      .read(mediaRepositoryProvider)
      .createFolderAndMoveMedia(albumName, items);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok
            ? l10n.snackbarAlbumCreatedAndMoved(albumName, items.length)
            : l10n.snackbarAlbumCreateFailed,
      ),
    ),
  );
  refreshFeedProviders(ref);
  onDone?.call();
}

Future<File?> resolveMediaFile(MediaItem item) async {
  if (usesFilesystemGallery) {
    final file = File(item.uri);
    if (await file.exists()) return file;
    return null;
  }
  final entity = await AssetEntity.fromId(item.uri);
  if (entity == null) return null;
  final file = await entity.originFile ?? await entity.file;
  if (file == null || !await file.exists()) return null;
  return file;
}

Future<void> bulkShare(
  WidgetRef ref,
  BuildContext context,
  Set<int> selectedIds, {
  VoidCallback? onDone,
}) async {
  if (selectedIds.isEmpty) return;

  final items = await resolveSelectedMedia(ref, selectedIds);
  final files = <XFile>[];
  for (final item in items) {
    final file = await resolveMediaFile(item);
    if (file != null) {
      files.add(XFile(file.path, name: item.displayName));
    }
  }

  if (!context.mounted) return;
  if (files.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarShareFailed)),
    );
    return;
  }

  await Share.shareXFiles(files);
  if (!context.mounted) return;
  onDone?.call();
}

Future<void> copyMediaToClipboard(
  WidgetRef ref,
  BuildContext context,
  Set<int> selectedIds,
) async {
  if (selectedIds.length != 1) return;

  final items = await resolveSelectedMedia(ref, selectedIds);
  if (items.isEmpty) return;
  final item = items.first;

  if (item.isVideo) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarCopyUnsupported)),
    );
    return;
  }

  if (!supportsImageClipboard) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarCopyFailed)),
    );
    return;
  }

  final file = await resolveMediaFile(item);
  if (file == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarCopyFailed)),
    );
    return;
  }

  try {
    final ok = await copyImageFileToClipboard(file);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? context.l10n.snackbarCopiedToClipboard
              : context.l10n.snackbarCopyFailed,
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarCopyFailed)),
    );
  }
}

Future<void> setMediaAsWallpaper(
  WidgetRef ref,
  BuildContext context,
  Set<int> selectedIds,
) async {
  if (selectedIds.length != 1) return;

  final items = await resolveSelectedMedia(ref, selectedIds);
  if (items.isEmpty) return;
  final item = items.first;

  if (item.isVideo || !Platform.isAndroid) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarWallpaperUnsupported)),
    );
    return;
  }

  if (!context.mounted) return;
  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.wallpaperConfirmTitle),
      content: Text(l10n.wallpaperConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.wallpaperConfirmAction),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final file = await resolveMediaFile(item);
  if (file == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarWallpaperFailed)),
    );
    return;
  }

  try {
    final result = await AsyncWallpaper.setWallpaper(
      WallpaperRequest(
        target: WallpaperTarget.home,
        sourceType: WallpaperSourceType.file,
        source: file.path,
        goToHome: false,
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? context.l10n.snackbarWallpaperSet
              : context.l10n.snackbarWallpaperFailed,
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.snackbarWallpaperFailed)),
    );
  }
}
