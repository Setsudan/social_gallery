import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/location/location_clustering.dart';
import 'package:social_gallery/core/location/reverse_geocoding_service.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/resolved_place.dart';

void main() {
  group('placeKeyFor', () {
    test('rounds coordinates to two decimal places', () {
      expect(placeKeyFor(46.204390, 6.143158), '46.20,6.14');
      expect(placeKeyFor(-33.8688, 151.2093), '-33.87,151.21');
    });
  });

  group('groupMediaByCountry', () {
    test('groups media by country and locality', () {
      final items = [
        _item(id: 1, lat: 46.204, lng: 6.143),
        _item(id: 2, lat: 46.205, lng: 6.144),
        _item(id: 3, lat: 40.7128, lng: -74.006),
      ];
      final places = {
        '46.20,6.14': const ResolvedPlace(
          placeKey: '46.20,6.14',
          latitude: 46.2,
          longitude: 6.14,
          countryName: 'Switzerland',
          locality: 'Geneva',
          geocodedAt: 0,
        ),
        '40.71,-74.01': const ResolvedPlace(
          placeKey: '40.71,-74.01',
          latitude: 40.71,
          longitude: -74.01,
          countryName: 'United States',
          locality: 'New York',
          geocodedAt: 0,
        ),
      };

      final groups = groupMediaByCountry(items: items, placesByKey: places);

      expect(groups.length, 2);
      expect(groups.first.countryName, 'Switzerland');
      expect(groups.first.count, 2);
      expect(groups.last.countryName, 'United States');
      expect(groups.last.count, 1);
    });
  });

  group('parseNominatimResponse', () {
    test('parses city and country from json', () {
      const body = '''
      {
        "address": {
          "city": "Geneva",
          "state": "Geneva",
          "country": "Switzerland",
          "country_code": "ch"
        }
      }
      ''';

      final result = ReverseGeocodingService.parseNominatimResponse(body);
      expect(result.countryCode, 'CH');
      expect(result.countryName, 'Switzerland');
      expect(result.locality, 'Geneva');
    });
  });
}

MediaItem _item({
  required int id,
  required double lat,
  required double lng,
}) {
  return MediaItem(
    id: id,
    uri: 'asset://$id',
    displayName: 'photo_$id.jpg',
    folderPath: '/camera',
    folderName: 'Camera',
    mimeType: 'image/jpeg',
    dateModified: 1000,
    dateAdded: 1000,
    size: 1000,
    latitude: lat,
    longitude: lng,
  );
}
