import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers/data_providers.dart';
import 'package:social_gallery/app/providers/feed_refresh_providers.dart';
import 'package:social_gallery/core/backup/backup_deep_link.dart';
import 'package:social_gallery/core/backup/desktop_availability_service.dart';
import 'package:social_gallery/core/backup/desktop_backup_controller.dart';
import 'package:social_gallery/core/backup/desktop_discovery_service.dart';
import 'package:social_gallery/core/backup/desktop_library_controller.dart';
import 'package:social_gallery/core/backup/pairing_service.dart';
import 'package:social_gallery/core/backup/vault_password_store.dart';
import 'package:social_gallery/core/cloud_backup/cloud_backup_controller.dart';
import 'package:social_gallery/core/cloud_backup/cloud_credential_store.dart';
import 'package:social_gallery/core/cloud_backup/cloud_vault_key_store.dart';
import 'package:social_gallery/core/notifications/cloud_backup_notification_service.dart';
import 'package:social_gallery/core/notifications/desktop_backup_notification_service.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';

final pairingServiceProvider = Provider((ref) {
  return PairingService(ref.watch(preferencesRepositoryProvider));
});

final pendingBackupPairProvider = StateProvider<BackupPairingParams?>(
  (ref) => null,
);

final desktopDiscoveryServiceProvider = Provider(
  (ref) => DesktopDiscoveryService(),
);

final vaultPasswordStoreProvider = Provider((ref) => VaultPasswordStore());

final desktopAvailabilityServiceProvider = Provider((ref) {
  return DesktopAvailabilityService(
    ref.watch(preferencesRepositoryProvider),
    ref.watch(desktopDiscoveryServiceProvider),
  );
});

final desktopBackupProvider =
    StateNotifierProvider<DesktopBackupController, DesktopBackupState>((ref) {
      final controller = DesktopBackupController(
        ref.watch(preferencesRepositoryProvider),
        ref.watch(mediaRepositoryProvider),
        ref.watch(desktopAvailabilityServiceProvider),
        ref.watch(pairingServiceProvider),
        ref.watch(desktopDiscoveryServiceProvider),
        ref.watch(vaultPasswordStoreProvider),
        notifications: usesFilesystemGallery
            ? null
            : ref.watch(desktopBackupNotificationServiceProvider),
        onLibraryRefresh: () async {
          if (usesFilesystemGallery) {
            await ref.read(gallerySyncProvider.notifier).run(force: true);
          }
        },
        onBackupFinished: () {
          if (!usesFilesystemGallery) {
            refreshFeedProvidersFromRef(ref);
          }
        },
        isGallerySyncRunning: () => ref.read(gallerySyncProvider).isRunning,
        waitForGallerySync: () async {
          while (ref.read(gallerySyncProvider).isRunning) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        },
      );
      controller.startHeartbeat();
      ref.onDispose(controller.dispose);
      return controller;
    });

final desktopLibraryProvider =
    StateNotifierProvider<DesktopLibraryController, DesktopLibraryState>((ref) {
      final controller = DesktopLibraryController(
        ref.watch(preferencesRepositoryProvider),
        ref.watch(desktopAvailabilityServiceProvider),
        ref.watch(vaultPasswordStoreProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

final cloudCredentialStoreProvider = Provider((ref) => CloudCredentialStore());

final cloudVaultKeyStoreProvider = Provider((ref) => CloudVaultKeyStore());

final cloudBackupNotificationServiceProvider = Provider(
  (ref) => CloudBackupNotificationService(),
);

final cloudBackupProvider =
    StateNotifierProvider<CloudBackupController, CloudBackupState>((ref) {
      final controller = CloudBackupController(
        ref.watch(preferencesRepositoryProvider),
        ref.watch(mediaRepositoryProvider),
        ref.watch(cloudCredentialStoreProvider),
        ref.watch(cloudVaultKeyStoreProvider),
        notifications: usesFilesystemGallery
            ? null
            : ref.watch(cloudBackupNotificationServiceProvider),
        onBackupFinished: () {
          if (!usesFilesystemGallery) {
            refreshFeedProvidersFromRef(ref);
          }
        },
        isGallerySyncRunning: () => ref.read(gallerySyncProvider).isRunning,
        waitForGallerySync: () async {
          while (ref.read(gallerySyncProvider).isRunning) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
          }
        },
      );
      if (ref.watch(preferencesRepositoryProvider).cloudBackupEnabled) {
        controller.startHeartbeat();
      }
      ref.onDispose(controller.dispose);
      return controller;
    });
