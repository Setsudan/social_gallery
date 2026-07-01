import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Shared flutter_map tile and interaction settings.
abstract final class AppMapConfig {
  static const userAgentPackageName = 'one.launay.social_gallery';

  static const _cartoVoyagerTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  static final interactionOptions = InteractionOptions(
    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
    cursorKeyboardRotationOptions: CursorKeyboardRotationOptions.disabled(),
  );

  static TileLayer tileLayer(BuildContext context) => TileLayer(
    urlTemplate: _cartoVoyagerTemplate,
    subdomains: const ['a', 'b', 'c', 'd'],
    retinaMode: RetinaMode.isHighDensity(context),
    userAgentPackageName: userAgentPackageName,
    maxNativeZoom: 20,
    maxZoom: 20,
  );

  static MapOptions mapOptions({
    required LatLng initialCenter,
    double initialZoom = 4,
  }) => MapOptions(
    initialCenter: initialCenter,
    initialZoom: initialZoom,
    initialRotation: 0,
    minZoom: 2,
    maxZoom: 20,
    interactionOptions: interactionOptions,
  );
}
