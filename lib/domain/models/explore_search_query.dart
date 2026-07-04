import 'package:flutter/foundation.dart';

/// Filters applied in Explore / Gallery search.
@immutable
class ExploreSearchQuery {
  const ExploreSearchQuery({
    this.text = '',
    this.label,
    this.color,
  });

  final String text;
  final String? label;
  final String? color;

  bool get isEmpty =>
      text.trim().isEmpty && (label == null || label!.isEmpty) && color == null;

  bool get hasContentFilters =>
      (label != null && label!.isNotEmpty) || color != null;

  String get cacheKey =>
      '${text.trim().toLowerCase()}|${label ?? ''}|${color ?? ''}';

  ExploreSearchQuery copyWith({
    String? text,
    String? label,
    String? color,
    bool clearLabel = false,
    bool clearColor = false,
  }) {
    return ExploreSearchQuery(
      text: text ?? this.text,
      label: clearLabel ? null : (label ?? this.label),
      color: clearColor ? null : (color ?? this.color),
    );
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
