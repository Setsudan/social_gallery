import 'package:flutter/material.dart';
import 'package:social_gallery/core/analysis/image_metrics.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';

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
  for (final label in query.labels) {
    parts.add(localize(exploreSearchLabelKey(label)));
  }
  if (query.color != null && query.color!.isNotEmpty) {
    parts.add(localize(exploreSearchColorKey(query.color!)));
  }
  if (query.placeQuery != null && query.placeQuery!.isNotEmpty) {
    parts.add(query.placeQuery!);
  }
  if (query.cameraMake != null && query.cameraMake!.isNotEmpty) {
    final cam = [
      query.cameraMake,
      if (query.cameraModel != null && query.cameraModel!.isNotEmpty)
        query.cameraModel,
    ].join(' ');
    parts.add(cam);
  }
  if (query.contentFilter != ExploreContentFilter.all) {
    parts.add(query.contentFilter.name);
  }
  if (query.dateFromMs != null || query.dateToMs != null) {
    parts.add('dated');
  }
  if (query.minFaceCount != null) {
    parts.add('faces');
  }
  return parts.join(' · ');
}

List<String> get searchableColorBuckets => kColorBuckets;
