import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/search/explore_query_parser.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';

void main() {
  test('cacheKey distinguishes filters', () {
    const a = ExploreSearchQuery(text: 'cat', color: 'blue');
    const b = ExploreSearchQuery(text: 'cat', color: 'red');
    expect(a, isNot(equals(b)));
    expect(a.cacheKey, isNot(b.cacheKey));
  });

  test('isEmpty reflects all fields', () {
    expect(const ExploreSearchQuery().isEmpty, isTrue);
    expect(const ExploreSearchQuery(labels: ['dog']).isEmpty, isFalse);
    expect(const ExploreSearchQuery(color: 'red').isEmpty, isFalse);
  });

  group('ExploreQueryParser', () {
    final parser = ExploreQueryParser(now: DateTime(2026, 7, 16));

    test('parses beach sunset last summer', () {
      final q = parser.parse('beach sunset last summer');
      expect(q.labels, contains('beach'));
      expect(q.color, 'orange');
      expect(q.dateFromMs, isNotNull);
      expect(q.dateToMs, isNotNull);
      final from = DateTime.fromMillisecondsSinceEpoch(q.dateFromMs!);
      expect(from.year, 2025);
      expect(from.month, 6);
    });

    test('parses cat in Paris as label and place', () {
      final q = parser.parse('cat in Paris');
      expect(q.labels, contains('cat'));
      expect(q.placeQuery?.toLowerCase(), contains('paris'));
    });

    test('parses screenshots', () {
      final q = parser.parse('screenshots');
      expect(q.contentFilter, ExploreContentFilter.screenshot);
    });

    test('parses iPhone 14 camera', () {
      final q = parser.parse('iPhone 14');
      expect(q.cameraMake, 'iphone');
      expect(q.cameraModel, '14');
    });
  });
}
