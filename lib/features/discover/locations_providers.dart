import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/location/location_clustering.dart';
import 'package:social_gallery/core/location/reverse_geocoding_service.dart';
import 'package:social_gallery/data/repositories/location_repository.dart';
import 'package:social_gallery/domain/models/map_location_cluster.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/place_group.dart';
import 'package:social_gallery/domain/models/resolved_place.dart';

void _invalidateLocationTargets(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(locationLibrarySnapshotProvider);
  invalidate(countryPlaceGroupsProvider);
  invalidate(mapClustersProvider);
  invalidate(geotaggedCountProvider);
}

void invalidateLocationProviders(WidgetRef ref) {
  _invalidateLocationTargets(ref.invalidate);
}

void invalidateLocationProvidersFromRef(Ref ref) {
  _invalidateLocationTargets(ref.invalidate);
}

final reverseGeocodingServiceProvider = Provider(
  (ref) => ReverseGeocodingService(),
);

final locationRepositoryProvider = Provider(
  (ref) => LocationRepository(ref.watch(databaseProvider)),
);

final locationLibrarySnapshotProvider =
    FutureProvider<({List<MediaItem> items, Map<String, ResolvedPlace> placesByKey})>((ref) async {
  final mediaRepo = ref.watch(mediaRepositoryProvider);
  final locationRepo = ref.watch(locationRepositoryProvider);
  final items = await mediaRepo.getMediaWithLocation();
  final placesByKey = await locationRepo.getAllCachedPlaces();
  return (items: items, placesByKey: placesByKey);
});

final countryPlaceGroupsProvider =
    FutureProvider<List<CountryPlaceGroup>>((ref) async {
  final snapshot = await ref.watch(locationLibrarySnapshotProvider.future);
  return groupMediaByCountry(
    items: snapshot.items,
    placesByKey: snapshot.placesByKey,
  );
});

final mapClustersProvider = FutureProvider<List<MapLocationCluster>>((ref) async {
  final snapshot = await ref.watch(locationLibrarySnapshotProvider.future);
  return buildMapClusters(items: snapshot.items);
});

final geotaggedCountProvider = FutureProvider<int>((ref) async {
  final snapshot = await ref.watch(locationLibrarySnapshotProvider.future);
  return snapshot.items.length;
});
