import 'package:flutter/material.dart';

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
  });

  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback onFavorite;
  final VoidCallback onUnfavorite;
  final VoidCallback onMove;
  final VoidCallback onTrash;
  final VoidCallback? onCreateAlbum;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('$selectedCount selected'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Cancel selection',
        onPressed: onCancel,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite),
          tooltip: 'Favorite selected',
          onPressed: onFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.favorite_border),
          tooltip: 'Unfavorite selected',
          onPressed: onUnfavorite,
        ),
        IconButton(
          icon: const Icon(Icons.drive_file_move_outlined),
          tooltip: 'Move selected',
          onPressed: onMove,
        ),
        if (onCreateAlbum != null)
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Create album and move',
            onPressed: onCreateAlbum,
          ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Move to trash',
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
