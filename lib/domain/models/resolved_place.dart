/// Reverse-geocoded place metadata for a coordinate grid cell.
class ResolvedPlace {
  const ResolvedPlace({
    required this.placeKey,
    required this.latitude,
    required this.longitude,
    this.countryCode,
    this.countryName,
    this.locality,
    this.adminArea,
    required this.geocodedAt,
  });

  final String placeKey;
  final double latitude;
  final double longitude;
  final String? countryCode;
  final String? countryName;
  final String? locality;
  final String? adminArea;
  final int geocodedAt;

  String get displayLocality =>
      locality?.trim().isNotEmpty == true
          ? locality!.trim()
          : adminArea?.trim().isNotEmpty == true
          ? adminArea!.trim()
          : '';

  String get displayCountry =>
      countryName?.trim().isNotEmpty == true ? countryName!.trim() : '';
}
