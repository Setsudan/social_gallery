import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';

void main() {
  test('cacheKey distinguishes filters', () {
    const a = ExploreSearchQuery(text: 'cat', color: 'blue');
    const b = ExploreSearchQuery(text: 'cat', color: 'red');
    expect(a, isNot(equals(b)));
    expect(a.cacheKey, isNot(b.cacheKey));
  });

  test('isEmpty reflects all fields', () {
    expect(const ExploreSearchQuery().isEmpty, isTrue);
    expect(const ExploreSearchQuery(label: 'dog').isEmpty, isFalse);
    expect(const ExploreSearchQuery(color: 'red').isEmpty, isFalse);
  });
}
