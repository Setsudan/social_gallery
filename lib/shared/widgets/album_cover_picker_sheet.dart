import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/animation/modal_sheet.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

Future<String?> showAlbumCoverPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required FolderInfo folder,
}) {
  return showAppModalBottomSheet<String>(
    context: context,
    ref: ref,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _AlbumCoverPickerSheet(folder: folder);
    },
  );
}

class _AlbumCoverPickerSheet extends ConsumerWidget {
  const _AlbumCoverPickerSheet({required this.folder});

  final FolderInfo folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mediaAsync = ref.watch(folderMediaProvider(folder.path));
    final currentCover = folder.customCoverUri?.trim();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
            ),
            child: Text(
              l10n.albumChooseCoverTitle(folder.name),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          mediaAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(OneUiSpacing.pageHorizontal),
              child: Text(l10n.albumCoverLoadError(error.toString())),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(OneUiSpacing.pageHorizontal),
                  child: Text(l10n.albumCoverNoPhotos),
                );
              }

              final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    OneUiSpacing.pageHorizontal,
                    0,
                    OneUiSpacing.pageHorizontal,
                    OneUiSpacing.md,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: OneUiSpacing.sm,
                    mainAxisSpacing: OneUiSpacing.sm,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isCurrent = currentCover != null &&
                        currentCover.isNotEmpty &&
                        currentCover == item.uri;

                    return _CoverPickerTile(
                      item: item,
                      isCurrent: isCurrent,
                      onTap: () {
                        AppHaptics.medium();
                        Navigator.pop(context, item.uri);
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoverPickerTile extends StatelessWidget {
  const _CoverPickerTile({
    required this.item,
    required this.isCurrent,
    required this.onTap,
  });

  final MediaItem item;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OneUiRadii.sm),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(OneUiRadii.sm),
            border: isCurrent
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(OneUiRadii.sm),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MediaThumbnail(
                  assetId: item.uri,
                  showVideoBadge: item.isVideo,
                ),
                if (isCurrent)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
