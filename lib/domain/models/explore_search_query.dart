import 'package:flutter/foundation.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';

/// Filters applied in Explore / Gallery search.
@immutable
class ExploreSearchQuery {
  const ExploreSearchQuery({
    this.text = '',
    this.labels = const [],
    this.color,
    this.placeQuery,
    this.dateFromMs,
    this.dateToMs,
    this.cameraMake,
    this.cameraModel,
    this.contentFilter = ExploreContentFilter.all,
    this.minFaceCount,
  });

  /// Remaining free-text tokens (filename, folder, labels, OCR).
  final String text;

  /// Object/animal labels that must all match (AND).
  final List<String> labels;

  final String? color;
  final String? placeQuery;
  final int? dateFromMs;
  final int? dateToMs;
  final String? cameraMake;
  final String? cameraModel;
  final ExploreContentFilter contentFilter;
  final int? minFaceCount;

  /// Backward-compatible single-label accessor used by chips.
  String? get label => labels.isEmpty ? null : labels.first;

  bool get isEmpty =>
      text.trim().isEmpty &&
      labels.isEmpty &&
      (color == null || color!.isEmpty) &&
      (placeQuery == null || placeQuery!.isEmpty) &&
      dateFromMs == null &&
      dateToMs == null &&
      (cameraMake == null || cameraMake!.isEmpty) &&
      (cameraModel == null || cameraModel!.isEmpty) &&
      contentFilter == ExploreContentFilter.all &&
      minFaceCount == null;

  bool get hasContentFilters =>
      labels.isNotEmpty ||
      (color != null && color!.isNotEmpty) ||
      (placeQuery != null && placeQuery!.isNotEmpty) ||
      dateFromMs != null ||
      dateToMs != null ||
      (cameraMake != null && cameraMake!.isNotEmpty) ||
      (cameraModel != null && cameraModel!.isNotEmpty) ||
      contentFilter != ExploreContentFilter.all ||
      minFaceCount != null;

  String get cacheKey => [
        text.trim().toLowerCase(),
        labels.map((l) => l.toLowerCase()).join(','),
        color ?? '',
        placeQuery?.toLowerCase() ?? '',
        dateFromMs?.toString() ?? '',
        dateToMs?.toString() ?? '',
        cameraMake?.toLowerCase() ?? '',
        cameraModel?.toLowerCase() ?? '',
        contentFilter.name,
        minFaceCount?.toString() ?? '',
      ].join('|');

  ExploreSearchQuery copyWith({
    String? text,
    List<String>? labels,
    String? color,
    String? placeQuery,
    int? dateFromMs,
    int? dateToMs,
    String? cameraMake,
    String? cameraModel,
    ExploreContentFilter? contentFilter,
    int? minFaceCount,
    bool clearLabels = false,
    bool clearColor = false,
    bool clearPlaceQuery = false,
    bool clearDateRange = false,
    bool clearCamera = false,
    bool clearContentFilter = false,
    bool clearMinFaceCount = false,
  }) {
    return ExploreSearchQuery(
      text: text ?? this.text,
      labels: clearLabels ? const [] : (labels ?? this.labels),
      color: clearColor ? null : (color ?? this.color),
      placeQuery: clearPlaceQuery ? null : (placeQuery ?? this.placeQuery),
      dateFromMs: clearDateRange ? null : (dateFromMs ?? this.dateFromMs),
      dateToMs: clearDateRange ? null : (dateToMs ?? this.dateToMs),
      cameraMake: clearCamera ? null : (cameraMake ?? this.cameraMake),
      cameraModel: clearCamera ? null : (cameraModel ?? this.cameraModel),
      contentFilter: clearContentFilter
          ? ExploreContentFilter.all
          : (contentFilter ?? this.contentFilter),
      minFaceCount:
          clearMinFaceCount ? null : (minFaceCount ?? this.minFaceCount),
    );
  }

  /// Convenience constructor matching the previous single-label API.
  factory ExploreSearchQuery.withLabel(String label, {String text = ''}) {
    return ExploreSearchQuery(text: text, labels: [label]);
  }

  @override
  bool operator ==(Object other) {
    return other is ExploreSearchQuery && other.cacheKey == cacheKey;
  }

  @override
  int get hashCode => cacheKey.hashCode;
}

/// Curated object/animal chips shown in search (display key -> search term).
const kExploreLabelChips = <String, String>{
  'searchChipCat': 'cat',
  'searchChipDog': 'dog',
  'searchChipPerson': 'person',
  'searchChipFood': 'food',
  'searchChipCar': 'car',
  'searchChipFlower': 'flower',
  'searchChipBottle': 'bottle',
  'searchChipBird': 'bird',
  'searchChipBeach': 'beach',
  'searchChipMountain': 'mountain',
};
