import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/location/app_map_config.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/domain/models/map_location_cluster.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/discover/locations_providers.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab>
    with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  bool _fittedBounds = false;
  int? _fittedClusterCount;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  String _pointKey(LatLng point) =>
      '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';

  void _fitBounds(List<MapLocationCluster> clusters) {
    if (clusters.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || clusters.isEmpty) return;
      final points = clusters
          .map((c) => LatLng(c.latitude, c.longitude))
          .toList();
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(48),
        ),
      );
      _fittedBounds = true;
      _fittedClusterCount = clusters.length;
    });
  }

  void _refitIfNeeded(List<MapLocationCluster> clusters) {
    if (_fittedBounds && _fittedClusterCount == clusters.length) return;
    _fittedBounds = false;
    _fitBounds(clusters);
  }

  List<MediaItem> _itemsForMarkers(
    List<Marker> clusterMarkers,
    Map<String, MapLocationCluster> clustersByPoint,
  ) {
    final items = <MediaItem>[];
    final seen = <int>{};
    for (final marker in clusterMarkers) {
      final cluster = clustersByPoint[_pointKey(marker.point)];
      if (cluster == null) continue;
      for (final item in cluster.mediaItems) {
        if (seen.add(item.id)) {
          items.add(item);
        }
      }
    }
    items.sort((a, b) {
      final aDate = a.dateTaken ?? a.dateModified;
      final bDate = b.dateTaken ?? b.dateModified;
      return bDate.compareTo(aDate);
    });
    return items;
  }

  void _showItemsSheet(List<MediaItem> items) {
    if (items.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OneUiSpacing.pageHorizontal,
                  0,
                  OneUiSpacing.pageHorizontal,
                  OneUiSpacing.sm,
                ),
                child: Text(
                  context.l10n.locationsPhotoCount(items.length),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: OneUiSpacing.pageHorizontal,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MapThumbnailTile(
                      item: item,
                      onTap: () {
                        Navigator.of(context).pop();
                        openMediaViewer(
                          context,
                          ref,
                          items: items,
                          item: item,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: OneUiSpacing.md),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final clustersAsync = ref.watch(mapClustersProvider);
    final l10n = context.l10n;

    return clustersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        title: l10n.locationsErrorTitle,
        message: l10n.locationsErrorMessage,
        icon: Icons.error_outline,
      ),
      data: (clusters) {
        if (clusters.isEmpty) {
          return EmptyState(
            title: l10n.locationsEmptyTitle,
            message: l10n.locationsEmptyMessage,
            icon: Icons.place_outlined,
          );
        }

        _refitIfNeeded(clusters);

        final clustersByPoint = {
          for (final cluster in clusters)
            _pointKey(LatLng(cluster.latitude, cluster.longitude)): cluster,
        };

        final markers = clusters.map((cluster) {
          final point = LatLng(cluster.latitude, cluster.longitude);
          return Marker(
            point: point,
            width: 40,
            height: 40,
            child: _MapPin(count: cluster.count),
          );
        }).toList();

        final center = LatLng(clusters.first.latitude, clusters.first.longitude);

        return FlutterMap(
          mapController: _mapController,
          options: AppMapConfig.mapOptions(initialCenter: center),
          children: [
            AppMapConfig.tileLayer(context),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 60,
                size: const Size(40, 40),
                markers: markers,
                builder: (context, clusterMarkers) {
                  return _MapPin(count: clusterMarkers.length);
                },
                onClusterTap: (cluster) {
                  final items = _itemsForMarkers(
                    cluster.markers,
                    clustersByPoint,
                  );
                  _showItemsSheet(items);
                },
                onMarkerTap: (marker) {
                  final items = _itemsForMarkers(
                    [marker],
                    clustersByPoint,
                  );
                  _showItemsSheet(items);
                },
              ),
            ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap',
                  onTap: () {},
                ),
                TextSourceAttribution(
                  'CARTO',
                  onTap: () {},
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.onPrimary, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MapThumbnailTile extends StatelessWidget {
  const _MapThumbnailTile({
    required this.item,
    required this.onTap,
  });

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(OneUiRadii.card),
        child: SizedBox(
          width: 96,
          height: 96,
          child: MediaThumbnail(
            assetId: item.uri,
            showVideoBadge: item.isVideo,
          ),
        ),
      ),
    );
  }
}
