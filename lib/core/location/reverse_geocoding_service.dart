import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/domain/models/resolved_place.dart';

/// Rounds coordinates to a grid cell key (~1.1 km at 2 decimal places).
String placeKeyFor(double latitude, double longitude) {
  final lat = latitude.toStringAsFixed(2);
  final lng = longitude.toStringAsFixed(2);
  return '$lat,$lng';
}

/// Reverse-geocodes coordinates with platform-specific backends.
class ReverseGeocodingService {
  ReverseGeocodingService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  DateTime? _lastNominatimRequest;

  static const _nominatimBase = 'https://nominatim.openstreetmap.org/reverse';
  static const _userAgent = 'social_gallery/0.0.10';

  bool get _usesNominatim =>
      kIsWeb ||
      usesFilesystemGallery ||
      (!Platform.isAndroid && !Platform.isIOS);

  Future<ResolvedPlace> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final key = placeKeyFor(latitude, longitude);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_usesNominatim) {
      final result = await _reverseGeocodeNominatim(latitude, longitude);
      return ResolvedPlace(
        placeKey: key,
        latitude: latitude,
        longitude: longitude,
        countryCode: result.countryCode,
        countryName: result.countryName,
        locality: result.locality,
        adminArea: result.adminArea,
        geocodedAt: now,
      );
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      return ResolvedPlace(
        placeKey: key,
        latitude: latitude,
        longitude: longitude,
        countryCode: placemark?.isoCountryCode,
        countryName: placemark?.country,
        locality: placemark?.locality ?? placemark?.subLocality,
        adminArea: placemark?.administrativeArea,
        geocodedAt: now,
      );
    } on PlatformException {
      // Coordinates with no resolvable address (ocean, remote areas, etc.).
      return ResolvedPlace(
        placeKey: key,
        latitude: latitude,
        longitude: longitude,
        geocodedAt: now,
      );
    }
  }

  Future<void> _throttleNominatim() async {
    final last = _lastNominatimRequest;
    if (last == null) return;
    final elapsed = DateTime.now().difference(last);
    if (elapsed < const Duration(seconds: 1)) {
      await Future<void>.delayed(const Duration(seconds: 1) - elapsed);
    }
  }

  Future<NominatimAddressResult> _reverseGeocodeNominatim(
    double latitude,
    double longitude,
  ) async {
    await _throttleNominatim();
    _lastNominatimRequest = DateTime.now();

    final uri = Uri.parse(_nominatimBase).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '10',
      },
    );

    final response = await _httpClient.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) {
      return const NominatimAddressResult();
    }

    return parseNominatimResponse(response.body);
  }

  /// Parses a Nominatim reverse-geocoding JSON response.
  @visibleForTesting
  static NominatimAddressResult parseNominatimResponse(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      if (address == null) return const NominatimAddressResult();

      final countryCode = address['country_code'] as String?;
      final countryName = address['country'] as String?;
      final locality =
          address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String? ??
          address['hamlet'] as String? ??
          address['municipality'] as String?;
      final adminArea =
          address['state'] as String? ??
          address['region'] as String? ??
          address['county'] as String?;

      return NominatimAddressResult(
        countryCode: countryCode?.toUpperCase(),
        countryName: countryName,
        locality: locality,
        adminArea: adminArea,
      );
    } catch (_) {
      return const NominatimAddressResult();
    }
  }
}

class NominatimAddressResult {
  const NominatimAddressResult({
    this.countryCode,
    this.countryName,
    this.locality,
    this.adminArea,
  });

  final String? countryCode;
  final String? countryName;
  final String? locality;
  final String? adminArea;
}
