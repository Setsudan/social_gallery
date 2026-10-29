import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/mappers/media_sync_merge.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';

void main() {
  MediaSyncMergeState existingState({
    bool isFavorite = true,
    bool isTrashed = true,
    double? latitude = 48,
    double? longitude = 2,
    int contentKind = 3,
  }) => MediaSyncMergeState(
    isFavorite: isFavorite,
    isTrashed: isTrashed,
    trashedAt: 123,
    originalPath: '/original',
    backupState: 2,
    lastSyncTime: 456,
    cloudBackupState: 1,
    cloudLastSyncTime: 789,
    cloudObjectKey: 'encrypted-object',
    latitude: latitude,
    longitude: longitude,
    contentKind: contentKind,
  );

  const scannedRow = MediaItemsCompanion(
    id: Value(1),
    uri: Value('device-asset'),
    isFavorite: Value(false),
    isTrashed: Value(false),
    contentKind: Value(0),
  );

  test('returns new media unchanged', () {
    expect(identical(mergeScannedMedia(scannedRow, null), scannedRow), isTrue);
  });

  test('preserves favorite, trash, and both backup states', () {
    final mergedRow = mergeScannedMedia(scannedRow, existingState());
    expect(mergedRow.uri.value, 'device-asset');
    expect(mergedRow.isFavorite.value, isTrue);
    expect(mergedRow.isTrashed.value, isTrue);
    expect(mergedRow.trashedAt.value, 123);
    expect(mergedRow.originalPath.value, '/original');
    expect(mergedRow.backupState.value, 2);
    expect(mergedRow.lastSyncTime.value, 456);
    expect(mergedRow.cloudBackupState.value, 1);
    expect(mergedRow.cloudLastSyncTime.value, 789);
    expect(mergedRow.cloudObjectKey.value, 'encrypted-object');
  });

  test(
    'does not override incoming favorite or trash when local flags are false',
    () {
      final incomingRow = scannedRow.copyWith(
        isFavorite: const Value(true),
        isTrashed: const Value(true),
        trashedAt: const Value(999),
      );
      final mergedRow = mergeScannedMedia(
        incomingRow,
        existingState(isFavorite: false, isTrashed: false),
      );
      expect(mergedRow.isFavorite.value, isTrue);
      expect(mergedRow.isTrashed.value, isTrue);
      expect(mergedRow.trashedAt.value, 999);
    },
  );

  test(
    'preserves valid existing coordinates for missing or zero incoming coordinates',
    () {
      for (final incomingRow in [
        scannedRow,
        scannedRow.copyWith(
          latitude: const Value(null),
          longitude: const Value(null),
        ),
        scannedRow.copyWith(
          latitude: const Value(0),
          longitude: const Value(5),
        ),
        scannedRow.copyWith(
          latitude: const Value(5),
          longitude: const Value(0),
        ),
      ]) {
        final mergedRow = mergeScannedMedia(incomingRow, existingState());
        expect(mergedRow.latitude.value, 48);
        expect(mergedRow.longitude.value, 2);
      }
    },
  );

  test('accepts new nonzero coordinates over existing coordinates', () {
    final mergedRow = mergeScannedMedia(
      scannedRow.copyWith(
        latitude: const Value(10),
        longitude: const Value(20),
      ),
      existingState(),
    );
    expect(mergedRow.latitude.value, 10);
    expect(mergedRow.longitude.value, 20);
  });

  test('does not restore incomplete or zero existing coordinates', () {
    for (final localState in [
      existingState(latitude: null),
      existingState(longitude: null),
      existingState(latitude: 0),
      existingState(longitude: 0),
    ]) {
      final mergedRow = mergeScannedMedia(scannedRow, localState);
      expect(mergedRow.latitude.present, isFalse);
      expect(mergedRow.longitude.present, isFalse);
    }
  });

  test(
    'preserves document classification except for newly detected screenshots',
    () {
      final mergedDocument = mergeScannedMedia(scannedRow, existingState());
      expect(mergedDocument.contentKind.value, MediaContentKind.document.value);
      final mergedScreenshot = mergeScannedMedia(
        scannedRow.copyWith(
          contentKind: Value(MediaContentKind.screenshot.value),
        ),
        existingState(),
      );
      expect(
        mergedScreenshot.contentKind.value,
        MediaContentKind.screenshot.value,
      );
      final mergedAbsentKind = mergeScannedMedia(
        const MediaItemsCompanion(),
        existingState(),
      );
      expect(
        mergedAbsentKind.contentKind.value,
        MediaContentKind.document.value,
      );
    },
  );

  test('preserves explicit null backup metadata from local state', () {
    const localState = MediaSyncMergeState(
      isFavorite: false,
      isTrashed: false,
      trashedAt: null,
      originalPath: null,
      backupState: 0,
      lastSyncTime: null,
      cloudBackupState: 0,
      cloudLastSyncTime: null,
      cloudObjectKey: null,
      latitude: null,
      longitude: null,
      contentKind: 0,
    );
    final mergedRow = mergeScannedMedia(scannedRow, localState);
    expect(mergedRow.lastSyncTime.present, isTrue);
    expect(mergedRow.lastSyncTime.value, isNull);
    expect(mergedRow.cloudLastSyncTime.value, isNull);
    expect(mergedRow.cloudObjectKey.value, isNull);
    expect(mergedRow.contentKind.value, 0);
  });
}
