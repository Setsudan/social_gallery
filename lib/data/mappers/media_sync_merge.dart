import 'package:drift/drift.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';

/// Keeps local organization and backup state when device metadata is rescanned.
MediaItemsCompanion mergeScannedMedia(
  MediaItemsCompanion scannedRow,
  MediaSyncMergeState? existingState,
) {
  if (existingState == null) return scannedRow;

  var mergedRow = scannedRow;
  if (existingState.isFavorite) {
    mergedRow = mergedRow.copyWith(isFavorite: const Value(true));
  }
  if (existingState.isTrashed) {
    mergedRow = mergedRow.copyWith(
      isTrashed: const Value(true),
      trashedAt: Value(existingState.trashedAt),
      originalPath: Value(existingState.originalPath),
    );
  }
  mergedRow = mergedRow.copyWith(
    backupState: Value(existingState.backupState),
    lastSyncTime: Value(existingState.lastSyncTime),
    cloudBackupState: Value(existingState.cloudBackupState),
    cloudLastSyncTime: Value(existingState.cloudLastSyncTime),
    cloudObjectKey: Value(existingState.cloudObjectKey),
  );

  final incomingLatitude = scannedRow.latitude.present
      ? scannedRow.latitude.value
      : null;
  final incomingLongitude = scannedRow.longitude.present
      ? scannedRow.longitude.value
      : null;
  final hasIncomingLocation = _hasNonzeroCoordinates(
    incomingLatitude,
    incomingLongitude,
  );
  final hasExistingLocation = _hasNonzeroCoordinates(
    existingState.latitude,
    existingState.longitude,
  );
  if (!hasIncomingLocation && hasExistingLocation) {
    mergedRow = mergedRow.copyWith(
      latitude: Value(existingState.latitude),
      longitude: Value(existingState.longitude),
    );
  }

  // Preserve document classification from OCR; screenshots re-derived.
  if (existingState.contentKind == MediaContentKind.document.value &&
      (!mergedRow.contentKind.present ||
          mergedRow.contentKind.value != MediaContentKind.screenshot.value)) {
    mergedRow = mergedRow.copyWith(
      contentKind: Value(MediaContentKind.document.value),
    );
  }
  return mergedRow;
}

bool _hasNonzeroCoordinates(double? latitude, double? longitude) =>
    latitude != null && longitude != null && latitude != 0 && longitude != 0;
