import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';

class MediaSelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MediaSelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.onCancel,
    required this.onFavorite,
    required this.onUnfavorite,
    required this.onMove,
    required this.onTrash,
    this.onCreateAlbum,
    this.onSetAlbumCover,
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onFavorite;
  final VoidCallback onUnfavorite;
  final VoidCallback onMove;
  final VoidCallback onTrash;
  final VoidCallback? onCreateAlbum;
  final VoidCallback? onSetAlbumCover;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppBar(
      title: Text(l10n.selectionCount(selectedCount)),
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.tooltipCancelSelection,
        onPressed: onCancel,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite),
          tooltip: l10n.tooltipFavoriteSelected,
          onPressed: onFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          tooltip: l10n.tooltipUnfavoriteSelected,
          onPressed: onUnfavorite,
        ),
        IconButton(
          icon: const Icon(Icons.drive_file_move_outlined),
          tooltip: l10n.tooltipMoveSelected,
          onPressed: onMove,
        ),
        if (onCreateAlbum != null)
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: l10n.tooltipCreateAlbumAndMove,
            onPressed: onCreateAlbum,
          ),
        if (onSetAlbumCover != null)
          IconButton(
            icon: const Icon(Icons.photo_album_outlined),
            tooltip: l10n.tooltipSetAlbumCover,
            onPressed: onSetAlbumCover,
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: l10n.tooltipMoveToTrash,
          onPressed: onTrash,
        ),
      ],
    );
  }
}

class AnimatedMediaSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const AnimatedMediaSelectionAppBar({
    super.key,
    required this.visible,
    required this.selectedCount,
    required this.onCancel,
    required this.onFavorite,
    required this.onUnfavorite,
    required this.onMove,
    required this.onTrash,
    this.onCreateAlbum,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOut,
  });

  final bool visible;
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onFavorite;
  final VoidCallback onUnfavorite;
  final VoidCallback onMove;
  final VoidCallback onTrash;
  final VoidCallback? onCreateAlbum;
  final Duration duration;
  final Curve curve;

  @override
  Size get preferredSize => Size.fromHeight(visible ? kToolbarHeight : 0);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: AnimatedSize(
        duration: duration,
        curve: curve,
        alignment: Alignment.topCenter,
        child: visible
            ? MediaSelectionAppBar(
                selectedCount: selectedCount,
                onCancel: onCancel,
                onFavorite: onFavorite,
                onUnfavorite: onUnfavorite,
                onMove: onMove,
                onTrash: onTrash,
                onCreateAlbum: onCreateAlbum,
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
