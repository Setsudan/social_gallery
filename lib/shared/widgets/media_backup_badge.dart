import 'package:flutter/material.dart';
import 'package:social_gallery/domain/models/backup_state.dart';
import 'package:social_gallery/domain/models/media_item.dart';

/// Resolves which LAN desktop backup badge to show, if any.
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

/// Whether the item has a successful encrypted cloud backup.
bool visibleCloudBackup(MediaItem item) =>
    item.cloudBackupState == MediaBackupState.backedUp;

/// Badges shown on thumbnails for desktop and/or cloud backup.
class MediaBackupBadge extends StatelessWidget {
  const MediaBackupBadge({
    super.key,
    this.state,
    this.cloudBackedUp = false,
  });

  final MediaBackupState? state;
  final bool cloudBackedUp;

  @override
  Widget build(BuildContext context) {
    final showDesktop = state == MediaBackupState.backedUp;
    if (!showDesktop && !cloudBackedUp) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 4,
      top: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDesktop)
            const _BadgeIcon(Icons.computer_rounded),
          if (showDesktop && cloudBackedUp) const SizedBox(width: 4),
          if (cloudBackedUp)
            const _BadgeIcon(Icons.cloud_done_rounded),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}
