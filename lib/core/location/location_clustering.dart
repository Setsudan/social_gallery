import 'package:social_gallery/core/location/reverse_geocoding_service.dart';
import 'package:social_gallery/domain/models/map_location_cluster.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/place_group.dart';
import 'package:social_gallery/domain/models/resolved_place.dart';

const unknownPlaceLabel = 'Unknown';

/// Groups geotagged media by country and city/locality using cached places.
List<CountryPlaceGroup> groupMediaByCountry({
  required List<MediaItem> items,
  required Map<String, ResolvedPlace> placesByKey,
  String unknownLabel = unknownPlaceLabel,
}) {
  final byCountry = <String, Map<String, List<MediaItem>>>{};

  for (final item in items) {
    final lat = item.latitude;
    final lng = item.longitude;
    if (lat == null || lng == null || !item.hasLocation) continue;

    final key = placeKeyFor(lat, lng);
    final place = placesByKey[key];
    final country = place?.displayCountry.isNotEmpty == true
        ? place!.displayCountry
        : unknownLabel;
    final locality = place?.displayLocality.isNotEmpty == true
        ? place!.displayLocality
        : unknownLabel;

    byCountry.putIfAbsent(country, () => {});
    byCountry[country]!.putIfAbsent(locality, () => []);
    byCountry[country]![locality]!.add(item);
  }

  final countries = byCountry.entries.map((countryEntry) {
    final cities = countryEntry.value.entries
        .map(
          (cityEntry) => PlaceGroup(
            countryName: countryEntry.key,
            locality: cityEntry.key,
            mediaItems: _sortedByDate(cityEntry.value),
          ),
        )
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final allMedia = cities.expand((c) => c.mediaItems).toList();

    return CountryPlaceGroup(
      countryName: countryEntry.key,
      cities: cities,
      allMedia: allMedia,
    );
  }).toList();

  countries.sort((a, b) => b.count.compareTo(a.count));
  return countries;
}

/// Builds map pin clusters, one per unique coordinate grid cell.
List<MapLocationCluster> buildMapClusters({
  required List<MediaItem> items,
}) {
  final byKey = <String, List<MediaItem>>{};

  for (final item in items) {
    final lat = item.latitude;
    final lng = item.longitude;
    if (lat == null || lng == null || !item.hasLocation) continue;

    final key = placeKeyFor(lat, lng);
    byKey.putIfAbsent(key, () => []);
    byKey[key]!.add(item);
  }

  return byKey.entries.map((entry) {
    final first = entry.value.first;
    return MapLocationCluster(
      latitude: first.latitude!,
      longitude: first.longitude!,
      mediaItems: _sortedByDate(entry.value),
    );
  }).toList();
}

List<MediaItem> _sortedByDate(List<MediaItem> items) {
  final sorted = [...items]
    ..sort((a, b) {
      final aDate = a.dateTaken ?? a.dateModified;
      final bDate = b.dateTaken ?? b.dateModified;
      return bDate.compareTo(aDate);
    });
  return sorted;
}

List<MediaItem> filterPlaceMedia({
  required List<MediaItem> items,
  required Map<String, ResolvedPlace> placesByKey,
  required String countryName,
  required String locality,
  String unknownLabel = unknownPlaceLabel,
}) {
  return items.where((item) {
    final lat = item.latitude;
    final lng = item.longitude;
    if (lat == null || lng == null || !item.hasLocation) return false;

    final key = placeKeyFor(lat, lng);
    final place = placesByKey[key];
    final country = place?.displayCountry.isNotEmpty == true
        ? place!.displayCountry
        : unknownLabel;
    final city = place?.displayLocality.isNotEmpty == true
        ? place!.displayLocality
        : unknownLabel;
    return country == countryName && city == locality;
  }).toList();
}
