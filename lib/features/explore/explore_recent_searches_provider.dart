import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/recent_search.dart';

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<RecentSearch>>(
  RecentSearchesNotifier.new,
);

class RecentSearchesNotifier extends Notifier<List<RecentSearch>> {
  @override
  List<RecentSearch> build() {
    return ref.read(preferencesRepositoryProvider).recentSearches;
  }

  Future<void> add(String query, {String? thumbnailUri}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final entry = RecentSearch(query: trimmed, thumbnailUri: thumbnailUri);
    await ref.read(preferencesRepositoryProvider).addRecentSearch(entry);
    state = ref.read(preferencesRepositoryProvider).recentSearches;
  }

  Future<void> remove(String query) async {
    await ref.read(preferencesRepositoryProvider).removeRecentSearch(query);
    state = ref.read(preferencesRepositoryProvider).recentSearches;
  }

  Future<void> clearAll() async {
    await ref.read(preferencesRepositoryProvider).clearRecentSearches();
    state = const [];
  }
}

const kExploreSearchSuggestions = [
  'Screenshots',
  'Videos',
  'Selfies',
  'Food',
  'Travel',
  'Nature',
  'Pets',
];
