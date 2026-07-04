import 'package:flutter/material.dart';
import 'package:social_gallery/domain/models/backup_state.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// Resolves which backup badge to show on a thumbnail, if any.
///
/// Backup check/in-progress states are communicated via push notifications
/// only, so this only surfaces the permanent "backed up" status.
MediaBackupState? visibleBackupState(
  MediaItem item, {
  int? syncingMediaId,
}) {
  return switch (item.backupState) {
    MediaBackupState.backedUp => MediaBackupState.backedUp,
    _ => null,
  };
}

/// Cloud badge shown on thumbnails that have been backed up.
class MediaBackupBadge extends StatelessWidget {
  const MediaBackupBadge({super.key, required this.state});

  final MediaBackupState state;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 4,
      top: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: switch (state) {
            MediaBackupState.backedUp => const Icon(
              Icons.cloud_done_rounded,
              color: Colors.white,
              size: 14,
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
