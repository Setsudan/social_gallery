import 'package:flutter/material.dart';
import 'package:social_gallery/core/analysis/image_metrics.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';

const kColorBucketColors = <String, Color>{
  'red': Color(0xFFE53935),
  'orange': Color(0xFFFB8C00),
  'yellow': Color(0xFFFDD835),
  'green': Color(0xFF43A047),
  'teal': Color(0xFF00897B),
  'blue': Color(0xFF1E88E5),
  'purple': Color(0xFF8E24AA),
  'pink': Color(0xFFD81B60),
  'brown': Color(0xFF6D4C41),
  'black': Color(0xFF212121),
  'white': Color(0xFFFAFAFA),
  'gray': Color(0xFF9E9E9E),
};

String exploreSearchLabelKey(String label) {
  return switch (label) {
    'cat' => 'searchChipCat',
    'dog' => 'searchChipDog',
    'person' => 'searchChipPerson',
    'food' => 'searchChipFood',
    'car' => 'searchChipCar',
    'flower' => 'searchChipFlower',
    'bottle' => 'searchChipBottle',
    'bird' => 'searchChipBird',
    'beach' => 'searchChipBeach',
    'mountain' => 'searchChipMountain',
    _ => label,
  };
}

String exploreSearchColorKey(String color) {
  return switch (color) {
    'red' => 'searchColorRed',
    'orange' => 'searchColorOrange',
    'yellow' => 'searchColorYellow',
    'green' => 'searchColorGreen',
    'teal' => 'searchColorTeal',
    'blue' => 'searchColorBlue',
    'purple' => 'searchColorPurple',
    'pink' => 'searchColorPink',
    'brown' => 'searchColorBrown',
    'black' => 'searchColorBlack',
    'white' => 'searchColorWhite',
    'gray' => 'searchColorGray',
    _ => color,
  };
}

String exploreSearchSummary({
  required ExploreSearchQuery query,
  required String Function(String key) localize,
}) {
  final parts = <String>[];
  if (query.text.trim().isNotEmpty) {
    parts.add(query.text.trim());
  }
  if (query.label != null && query.label!.isNotEmpty) {
    parts.add(localize(exploreSearchLabelKey(query.label!)));
  }
  if (query.color != null && query.color!.isNotEmpty) {
    parts.add(localize(exploreSearchColorKey(query.color!)));
  }
  return parts.join(' · ');
}

List<String> get searchableColorBuckets => kColorBuckets;
