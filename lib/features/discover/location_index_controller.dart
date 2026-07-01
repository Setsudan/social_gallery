import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/location/reverse_geocoding_service.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/domain/models/resolved_place.dart';
import 'package:social_gallery/features/discover/locations_providers.dart';

/// Progress and results of background location indexing.
class LocationIndexState {
  const LocationIndexState({
    this.isIndexing = false,
    this.indexed = 0,
    this.total = 0,
    this.isComplete = false,
    this.isBackfilling = false,
    this.hasError = false,
  });

  final bool isIndexing;
  final int indexed;
  final int total;
  final bool isComplete;
  final bool isBackfilling;
  final bool hasError;

  double get progress => total == 0 ? 0 : indexed / total;
}

/// Reverse-geocodes unique coordinate cells for geotagged media.
class LocationIndexController extends StateNotifier<LocationIndexState> {
  LocationIndexController(this._ref) : super(const LocationIndexState());

  final Ref _ref;

  void ensureStarted() {
    if (state.isIndexing || state.isComplete) return;
    unawaited(_run());
  }

  /// Re-runs GPS backfill and geocoding after the library index changes.
  void scheduleAfterLibrarySync() {
    if (state.isIndexing) return;
    unawaited(_run());
  }

  Future<void> refresh() async {
    if (state.isIndexing) return;
    await _run();
  }

  Future<void> _run() async {
    state = const LocationIndexState(isIndexing: true);
    await startIndexing();
  }

  Future<void> _waitForGallerySync() async {
    while (_ref.read(gallerySyncProvider).isRunning) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> startIndexing() async {
    try {
      await _waitForGallerySync();

      final mediaRepo = _ref.read(mediaRepositoryProvider);
      final locationRepo = _ref.read(locationRepositoryProvider);
      final geocoding = _ref.read(reverseGeocodingServiceProvider);

      state = const LocationIndexState(isIndexing: true, isBackfilling: true);
      await _ref.read(mediaPermissionServiceProvider).request();

      await mediaRepo.backfillMediaLocations(
        onProgress: (processed, total) {
          state = LocationIndexState(
            isIndexing: true,
            isBackfilling: true,
            indexed: processed,
            total: total,
          );
        },
      );

      final items = await mediaRepo.getMediaWithLocation();
      if (items.isEmpty) {
        state = const LocationIndexState(isComplete: true);
        invalidateLocationProvidersFromRef(_ref);
        return;
      }

      final uniqueKeys = <String, ({double lat, double lng})>{};
      for (final item in items) {
        final lat = item.latitude;
        final lng = item.longitude;
        if (lat == null || lng == null) continue;
        final key = placeKeyFor(lat, lng);
        uniqueKeys.putIfAbsent(key, () => (lat: lat, lng: lng));
      }

      final cached = await locationRepo.getAllCachedPlaces();
      final pending = uniqueKeys.entries
          .where((e) => !cached.containsKey(e.key))
          .toList();

      if (pending.isEmpty) {
        state = LocationIndexState(
          isComplete: true,
          indexed: uniqueKeys.length,
          total: uniqueKeys.length,
        );
        invalidateLocationProvidersFromRef(_ref);
        return;
      }

      state = LocationIndexState(
        isIndexing: true,
        indexed: uniqueKeys.length - pending.length,
        total: uniqueKeys.length,
      );

      var indexed = uniqueKeys.length - pending.length;
      for (final entry in pending) {
        final coords = entry.value;
        try {
          final place = await geocoding.reverseGeocode(
            latitude: coords.lat,
            longitude: coords.lng,
          );
          await locationRepo.upsertPlace(place);
        } catch (_) {
          await locationRepo.upsertPlace(
            ResolvedPlace(
              placeKey: entry.key,
              latitude: coords.lat,
              longitude: coords.lng,
              geocodedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
        indexed++;
        state = LocationIndexState(
          isIndexing: true,
          indexed: indexed,
          total: uniqueKeys.length,
        );
      }

      state = LocationIndexState(
        isComplete: true,
        indexed: uniqueKeys.length,
        total: uniqueKeys.length,
      );
      invalidateLocationProvidersFromRef(_ref);
    } catch (_) {
      state = LocationIndexState(
        isIndexing: false,
        indexed: state.indexed,
        total: state.total,
        hasError: true,
      );
    }
  }
}

final locationIndexControllerProvider =
    StateNotifierProvider<LocationIndexController, LocationIndexState>(
  (ref) => LocationIndexController(ref),
);
