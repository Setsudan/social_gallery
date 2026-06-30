import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/folder_picker_sheet.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';

Future<bool> confirmBulkTrashDialog(BuildContext context, int count) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Move to trash'),
      content: Text(
        'Move $count items to trash? You can restore them from Settings.',
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
    SnackBar(content: Text('Moved ${items.length} item(s) to trash')),
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
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        moved == items.length
            ? 'Moved $moved item(s)'
            : moved == 0
                ? 'Could not move items. Approve the system prompt if shown, '
                    'or check storage access in Settings.'
                : 'Moved $moved of ${items.length} item(s)',
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

  final nameController = TextEditingController();
  final albumName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create album'),
      content: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          labelText: 'Album name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) Navigator.pop(context, name);
          },
          child: const Text('Create and move'),
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
            ? 'Created "$albumName" and moved ${items.length} item(s)'
            : 'Could not create album. Check storage access.',
      ),
    ),
  );
  refreshFeedProviders(ref);
  onDone?.call();
}
