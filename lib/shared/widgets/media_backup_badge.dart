import 'package:flutter/material.dart';
import 'package:social_gallery/domain/models/backup_state.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// Resolves which backup badge to show on a thumbnail, if any.
MediaBackupState? visibleBackupState(
  MediaItem item, {
  int? syncingMediaId,
}) {
  if (syncingMediaId == item.id) {
    return MediaBackupState.inProgress;
  }
  return switch (item.backupState) {
    MediaBackupState.backedUp => MediaBackupState.backedUp,
    MediaBackupState.inProgress => MediaBackupState.inProgress,
    _ => null,
  };
}

/// Cloud or progress overlay for backed-up / in-progress media.
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
            MediaBackupState.inProgress => const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}
