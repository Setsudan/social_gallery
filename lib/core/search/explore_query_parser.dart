import 'package:social_gallery/core/analysis/image_metrics.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/media_content_kind.dart';

/// Rule-based natural-language parser for Explore search.
class ExploreQueryParser {
  ExploreQueryParser({DateTime? now}) : _now = now ?? DateTime.now();

  final DateTime _now;

  static const _stopWords = {
    'a',
    'an',
    'the',
    'of',
    'in',
    'on',
    'at',
    'to',
    'for',
    'with',
    'from',
    'by',
    'and',
    'or',
    'my',
    'me',
    'photos',
    'photo',
    'pictures',
    'picture',
    'images',
    'image',
    'near',
    'around',
  };

  static const _labelSynonyms = <String, String>{
    'cat': 'cat',
    'cats': 'cat',
    'kitten': 'cat',
    'dog': 'dog',
    'dogs': 'dog',
    'puppy': 'dog',
    'person': 'person',
    'people': 'person',
    'human': 'person',
    'food': 'food',
    'meal': 'food',
    'car': 'car',
    'cars': 'car',
    'vehicle': 'car',
    'flower': 'flower',
    'flowers': 'flower',
    'bottle': 'bottle',
    'bird': 'bird',
    'birds': 'bird',
    'beach': 'beach',
    'seashore': 'beach',
    'mountain': 'mountain',
    'mountains': 'mountain',
  };

  static const _colorSynonyms = <String, String>{
    'sunset': 'orange',
    'sunrise': 'orange',
    'golden': 'yellow',
    'night': 'black',
    'dark': 'black',
    'bright': 'white',
  };

  static const _cameraBrands = <String>{
    'apple',
    'iphone',
    'samsung',
    'google',
    'pixel',
    'canon',
    'nikon',
    'sony',
    'huawei',
    'xiaomi',
    'oneplus',
    'motorola',
    'lg',
    'olympus',
    'fujifilm',
    'fuji',
    'panasonic',
    'leica',
    'gopro',
  };

  static final _yearPattern = RegExp(r'^(?:in\s+)?(20\d{2}|19\d{2})$');
  static final _inYearPattern = RegExp(r'\bin\s+(20\d{2}|19\d{2})\b');
  static final _monthNames = <String, int>{
    'january': 1,
    'jan': 1,
    'february': 2,
    'feb': 2,
    'march': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'june': 6,
    'jun': 6,
    'july': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oct': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dec': 12,
  };

  ExploreSearchQuery parse(String raw) {
    var working = raw.trim().toLowerCase();
    if (working.isEmpty) return const ExploreSearchQuery();

    final labels = <String>{};
    String? color;
    String? placeQuery;
    int? dateFromMs;
    int? dateToMs;
    String? cameraMake;
    String? cameraModel;
    var contentFilter = ExploreContentFilter.all;
    int? minFaceCount;

    // Multi-word phrases first.
    if (working.contains('last summer')) {
      final range = _lastSummerRange();
      dateFromMs = range.$1;
      dateToMs = range.$2;
      working = working.replaceAll('last summer', ' ');
    }
    if (working.contains('this summer')) {
      final range = _summerRange(_now.year);
      dateFromMs = range.$1;
      dateToMs = range.$2;
      working = working.replaceAll('this summer', ' ');
    }
    if (working.contains('this year')) {
      dateFromMs = DateTime(_now.year).millisecondsSinceEpoch;
      dateToMs = DateTime(_now.year + 1).millisecondsSinceEpoch - 1;
      working = working.replaceAll('this year', ' ');
    }
    if (working.contains('last year')) {
      dateFromMs = DateTime(_now.year - 1).millisecondsSinceEpoch;
      dateToMs = DateTime(_now.year).millisecondsSinceEpoch - 1;
      working = working.replaceAll('last year', ' ');
    }
    if (working.contains('yesterday')) {
      final day = DateTime(_now.year, _now.month, _now.day)
          .subtract(const Duration(days: 1));
      dateFromMs = day.millisecondsSinceEpoch;
      dateToMs =
          day.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
      working = working.replaceAll('yesterday', ' ');
    }
    if (working.contains('today')) {
      final day = DateTime(_now.year, _now.month, _now.day);
      dateFromMs = day.millisecondsSinceEpoch;
      dateToMs =
          day.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;
      working = working.replaceAll('today', ' ');
    }
    if (working.contains('screen shot') || working.contains('screen-shot')) {
      contentFilter = ExploreContentFilter.screenshot;
      working = working
          .replaceAll('screen shot', ' ')
          .replaceAll('screen-shot', ' ');
    }

    final inYear = _inYearPattern.firstMatch(working);
    if (inYear != null) {
      final year = int.parse(inYear.group(1)!);
      dateFromMs = DateTime(year).millisecondsSinceEpoch;
      dateToMs = DateTime(year + 1).millisecondsSinceEpoch - 1;
      working = working.replaceFirst(_inYearPattern, ' ');
    }

    // Tokenize remaining.
    final tokens = working
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final leftover = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (_stopWords.contains(token)) continue;

      if (token == 'screenshots' || token == 'screenshot') {
        contentFilter = ExploreContentFilter.screenshot;
        continue;
      }
      if (token == 'document' ||
          token == 'documents' ||
          token == 'receipt' ||
          token == 'receipts' ||
          token == 'note' ||
          token == 'notes' ||
          token == 'meme' ||
          token == 'memes') {
        contentFilter = ExploreContentFilter.document;
        leftover.add(token);
        continue;
      }
      if (token == 'video' || token == 'videos') {
        contentFilter = ExploreContentFilter.video;
        continue;
      }
      if (token == 'photo' || token == 'photos' || token == 'image') {
        if (contentFilter == ExploreContentFilter.all) {
          contentFilter = ExploreContentFilter.image;
        }
        continue;
      }
      if (token == 'selfie' || token == 'selfies' || token == 'portrait') {
        minFaceCount = 1;
        continue;
      }

      final yearMatch = _yearPattern.firstMatch(token);
      if (yearMatch != null) {
        final year = int.parse(yearMatch.group(1)!);
        dateFromMs = DateTime(year).millisecondsSinceEpoch;
        dateToMs = DateTime(year + 1).millisecondsSinceEpoch - 1;
        continue;
      }

      final month = _monthNames[token];
      if (month != null) {
        var year = _now.year;
        // Optional following year token.
        if (i + 1 < tokens.length) {
          final nextYear = int.tryParse(tokens[i + 1]);
          if (nextYear != null && nextYear >= 1900 && nextYear <= 2100) {
            year = nextYear;
            i++;
          }
        }
        dateFromMs = DateTime(year, month).millisecondsSinceEpoch;
        final monthEnd = month == 12
            ? DateTime(year + 1, 1)
            : DateTime(year, month + 1);
        dateToMs = monthEnd.millisecondsSinceEpoch - 1;
        continue;
      }

      if (_labelSynonyms.containsKey(token)) {
        labels.add(_labelSynonyms[token]!);
        continue;
      }

      if (_colorSynonyms.containsKey(token)) {
        color ??= _colorSynonyms[token];
        continue;
      }

      if (kColorBuckets.contains(token)) {
        color ??= token;
        continue;
      }

      if (_cameraBrands.contains(token)) {
        cameraMake ??= token;
        // Capture following model token (e.g. "iphone 14", "pixel 8").
        if (i + 1 < tokens.length && RegExp(r'^\d').hasMatch(tokens[i + 1])) {
          cameraModel = tokens[i + 1];
          i++;
        }
        continue;
      }

      // Capitalized place-looking leftovers stay as place + free text.
      leftover.add(token);
    }

    // Known chip labels already consumed; leftover may be place names.
    if (leftover.isNotEmpty) {
      // Prefer treating multi-word leftovers as place when no place yet and
      // tokens look like location words (not already classified).
      final placeCandidates = leftover
          .where((t) => !_labelSynonyms.containsKey(t))
          .toList();
      if (placeCandidates.isNotEmpty) {
        // Use leftover tokens as place query for location_place_cache match.
        placeQuery = placeCandidates.join(' ');
      }
    }

    final freeText = leftover.join(' ').trim();

    return ExploreSearchQuery(
      text: freeText,
      labels: labels.toList(),
      color: color,
      placeQuery: placeQuery,
      dateFromMs: dateFromMs,
      dateToMs: dateToMs,
      cameraMake: cameraMake,
      cameraModel: cameraModel,
      contentFilter: contentFilter,
      minFaceCount: minFaceCount,
    );
  }

  (int, int) _lastSummerRange() {
    final year = _now.month >= 9 ? _now.year : _now.year - 1;
    return _summerRange(year);
  }

  (int, int) _summerRange(int year) {
    final from = DateTime(year, 6, 1).millisecondsSinceEpoch;
    final to = DateTime(year, 9, 1).millisecondsSinceEpoch - 1;
    return (from, to);
  }
}
