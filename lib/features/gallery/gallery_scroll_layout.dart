import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/group_media_by_period.dart';

/// One lazy row in the gallery timeline (section title or a strip of tiles).
enum GalleryTimelineRowKind { header, tiles, loader }

class GalleryTimelineRow {
  const GalleryTimelineRow.header({
    required this.rowKey,
    required this.label,
    required this.flatIndex,
  }) : kind = GalleryTimelineRowKind.header,
       items = const [],
       bottomGap = 0;

  const GalleryTimelineRow.tiles({
    required this.rowKey,
    required this.items,
    required this.flatIndex,
    required this.bottomGap,
  }) : kind = GalleryTimelineRowKind.tiles,
       label = null;

  const GalleryTimelineRow.loader({required this.flatIndex})
    : kind = GalleryTimelineRowKind.loader,
      rowKey = 'loader',
      label = null,
      items = const [],
      bottomGap = 0;

  final GalleryTimelineRowKind kind;
  final String rowKey;
  final String? label;
  final List<MediaItem> items;

  /// Index of the first media item this row belongs to, in timeline order.
  final int flatIndex;

  /// Extra space under a tile row (grid gap, or the section's bottom padding).
  final double bottomGap;
}

/// Fixed-extent rows for the grouped gallery.
///
/// A date section used to be its own sliver. Hundreds of those slivers are
/// walked on every scroll frame. This flattens them into one list whose
/// extents are known up front so the viewport only lays out visible rows.
class GalleryTimelineLayout {
  GalleryTimelineLayout._({
    required this.rows,
    required this.columns,
    required this.viewportWidth,
    required this.headerExtent,
    required this.cellExtent,
    required this.offsets,
    required this.indexByKey,
  });

  static const double tileGap = 2;
  static const double horizontalInset = 2;
  static const double groupBottomGap = 8;
  static const double loaderExtent = 84;

  final List<GalleryTimelineRow> rows;
  final int columns;
  final double viewportWidth;
  final double headerExtent;
  final double cellExtent;
  final List<double> offsets;
  final Map<String, int> indexByKey;

  static double cellExtentFor({
    required double viewportWidth,
    required int columns,
  }) {
    if (columns <= 0 || !viewportWidth.isFinite || viewportWidth <= 0) {
      return 1;
    }
    final inner = viewportWidth - horizontalInset * 2;
    final widthForCells = inner - tileGap * (columns - 1);
    if (widthForCells <= 0) return 1;
    // Floor to 1/64px so a full row cannot exceed the viewport by a float ulp.
    final raw = widthForCells / columns;
    final cell = (raw * 64).floorToDouble() / 64;
    return cell < 1 ? 1 : cell;
  }

  factory GalleryTimelineLayout.build({
    required List<MediaPeriodGroup> groups,
    required int columns,
    required double viewportWidth,
    required double headerExtent,
    required bool showLoader,
  }) {
    final safeColumns = columns < 1 ? 1 : columns;
    final cell = cellExtentFor(
      viewportWidth: viewportWidth,
      columns: safeColumns,
    );
    final rows = <GalleryTimelineRow>[];
    final indexByKey = <String, int>{};
    var flat = 0;

    for (final group in groups) {
      final headerKey = 'h:${group.key}';
      indexByKey[headerKey] = rows.length;
      rows.add(
        GalleryTimelineRow.header(
          rowKey: headerKey,
          label: group.label,
          flatIndex: flat,
        ),
      );

      final items = group.items;
      if (items.isEmpty) continue;
      for (var start = 0; start < items.length; start += safeColumns) {
        final end = start + safeColumns < items.length
            ? start + safeColumns
            : items.length;
        final slice = items.sublist(start, end);
        final last = end == items.length;
        final rowKey = 't:${slice.first.id}';
        indexByKey[rowKey] = rows.length;
        rows.add(
          GalleryTimelineRow.tiles(
            rowKey: rowKey,
            items: slice,
            flatIndex: flat,
            bottomGap: last ? groupBottomGap : tileGap,
          ),
        );
        flat += slice.length;
      }
    }

    if (showLoader) {
      indexByKey['loader'] = rows.length;
      rows.add(GalleryTimelineRow.loader(flatIndex: flat));
    }

    final offsets = List<double>.filled(rows.length + 1, 0);
    var y = 0.0;
    for (var i = 0; i < rows.length; i++) {
      offsets[i] = y;
      y += _extentOf(rows[i], headerExtent: headerExtent, cellExtent: cell);
    }
    offsets[rows.length] = y;

    return GalleryTimelineLayout._(
      rows: rows,
      columns: safeColumns,
      viewportWidth: viewportWidth,
      headerExtent: headerExtent,
      cellExtent: cell,
      offsets: offsets,
      indexByKey: indexByKey,
    );
  }

  double extentAt(int index) {
    if (index < 0 || index >= rows.length) return 0;
    return offsets[index + 1] - offsets[index];
  }

  /// First media index at or below [pixels], for thumbnail prefetch.
  int flatIndexAt(double pixels) {
    if (rows.isEmpty) return 0;
    if (pixels <= 0) return rows.first.flatIndex;
    if (pixels >= offsets.last) {
      for (var i = rows.length - 1; i >= 0; i--) {
        if (rows[i].kind != GalleryTimelineRowKind.loader) {
          return rows[i].flatIndex;
        }
      }
      return 0;
    }
    var lo = 0;
    var hi = rows.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (offsets[mid + 1] <= pixels) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return rows[lo].flatIndex;
  }

  int? indexForKey(Object? keyValue) {
    if (keyValue is! String) return null;
    return indexByKey[keyValue];
  }
}

double _extentOf(
  GalleryTimelineRow row, {
  required double headerExtent,
  required double cellExtent,
}) {
  switch (row.kind) {
    case GalleryTimelineRowKind.header:
      return headerExtent;
    case GalleryTimelineRowKind.tiles:
      return cellExtent + row.bottomGap;
    case GalleryTimelineRowKind.loader:
      return GalleryTimelineLayout.loaderExtent;
  }
}
