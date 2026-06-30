/// One explore search entry persisted in SharedPreferences.
class RecentSearch {
  const RecentSearch({
    required this.query,
    this.thumbnailUri,
  });

  final String query;
  final String? thumbnailUri;

  Map<String, dynamic> toJson() => {
        'query': query,
        if (thumbnailUri != null) 'thumbnailUri': thumbnailUri,
      };

  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      query: json['query'] as String,
      thumbnailUri: json['thumbnailUri'] as String?,
    );
  }
}
