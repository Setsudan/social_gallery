import 'dart:io';

import 'package:exif/exif.dart' as exif;

class ExifData {
  const ExifData({
    this.cameraMake,
    this.cameraModel,
    this.iso,
    this.shutterSpeed,
    this.focalLength,
    this.aperture,
    this.latitude,
    this.longitude,
  });

  final String? cameraMake;
  final String? cameraModel;
  final int? iso;
  final String? shutterSpeed;
  final double? focalLength;
  final String? aperture;
  final double? latitude;
  final double? longitude;
}

Future<ExifData?> readExifFromPath(String? filePath) async {
  if (filePath == null || filePath.isEmpty) return null;
  try {
    final file = File(filePath);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    return parseExifData(bytes);
  } catch (_) {}
  return null;
}

Future<ExifData?> parseExifData(List<int> bytes) async {
  try {
    final tags = await exif.readExifFromBytes(bytes);
    if (tags.isEmpty) return null;

    final make = tags['Image Make']?.printable;
    final model = tags['Image Model']?.printable;
    final isoStr = tags['EXIF ISOSpeedRatings']?.printable;
    final shutter = tags['EXIF ExposureTime']?.printable;
    final focalStr = tags['EXIF FocalLength']?.printable;
    final apertureStr = tags['EXIF FNumber']?.printable;

    double? lat;
    double? lng;
    final latRef = tags['GPS GPSLatitudeRef']?.printable;
    final latVals = tags['GPS GPSLatitude']?.values;
    final lngRef = tags['GPS GPSLongitudeRef']?.printable;
    final lngVals = tags['GPS GPSLongitude']?.values;
    if (latVals != null && latVals.length >= 3) {
      lat = _dmsToDecimal(latVals.toList(), latRef == 'S');
    }
    if (lngVals != null && lngVals.length >= 3) {
      lng = _dmsToDecimal(lngVals.toList(), lngRef == 'W');
    }

    return ExifData(
      cameraMake: make,
      cameraModel: model,
      iso: int.tryParse(isoStr ?? ''),
      shutterSpeed: shutter,
      focalLength: double.tryParse(focalStr ?? ''),
      aperture: apertureStr != null ? 'f/$apertureStr' : null,
      latitude: lat,
      longitude: lng,
    );
  } catch (_) {
    return null;
  }
}

double _dmsToDecimal(List<dynamic> values, bool negative) {
  double d = 0;
  if (values.isNotEmpty) d += _toDouble(values[0]);
  if (values.length > 1) d += _toDouble(values[1]) / 60;
  if (values.length > 2) d += _toDouble(values[2]) / 3600;
  return negative ? -d : d;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is exif.Ratio) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
