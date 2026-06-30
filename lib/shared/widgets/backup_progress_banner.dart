import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/backup/desktop_backup_controller.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';

/// Top-of-screen banner shown on mobile while a desktop backup is running.
class BackupProgressBanner extends ConsumerWidget {
  const BackupProgressBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (usesFilesystemGallery) {
      return const SizedBox.shrink();
    }

    final backup = ref.watch(desktopBackupProvider);
    if (!backup.showsProgressUi) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final progress = backup.progress;
    final subtitle = backup.total > 0
        ? '${backup.processed} / ${backup.total}'
        : backup.detail;

    return Material(
      elevation: 2,
      color: theme.colorScheme.primaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: progress != null
                    ? CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimaryContainer,
                      )
                    : CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _phaseTitle(backup),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _phaseTitle(DesktopBackupState backup) {
    return switch (backup.phase) {
      DesktopBackupPhase.discovering => 'Preparing backup',
      DesktopBackupPhase.reconciling => 'Reconciling',
      DesktopBackupPhase.verifying => 'Verifying',
      DesktopBackupPhase.syncing => 'Backup in progress',
      _ => 'Backup in progress',
    };
  }
}
