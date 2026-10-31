import 'package:social_gallery/domain/models/media_item.dart';

/// Reason why an item was chosen as the keeper in a duplicate group.
enum KeeperReason { newest, largestFile, highestResolution, first }

/// Result of selecting the best item from a duplicate group.
class KeeperSuggestion {
  const KeeperSuggestion({required this.keeper, required this.reason});

  final MediaItem keeper;
  final KeeperReason reason;
}

/// Picks the keeper in a duplicate/similar group (newest, then largest file/resolution).
class SuggestKeepBest {
  MediaItem call(List<MediaItem> items) {
    return suggestWithReason(items).keeper;
  }

  /// Returns the suggested keeper along with the reason it was chosen.
  KeeperSuggestion suggestWithReason(List<MediaItem> items) {
    if (items.isEmpty) {
      throw ArgumentError('items cannot be empty');
    }
    if (items.length == 1) {
      return KeeperSuggestion(keeper: items.first, reason: KeeperReason.first);
    }

    final sorted = [...items]
      ..sort((a, b) {
        final dateCmp = b.sortDate.compareTo(a.sortDate);
        if (dateCmp != 0) return dateCmp;
        final sizeCmp = b.size.compareTo(a.size);
        if (sizeCmp != 0) return sizeCmp;
        return b.pixelCount.compareTo(a.pixelCount);
      });

    final keeper = sorted.first;
    final second = sorted[1];

    KeeperReason reason;
    if (keeper.sortDate > second.sortDate) {
      reason = KeeperReason.newest;
    } else if (keeper.size > second.size) {
      reason = KeeperReason.largestFile;
    } else if (keeper.pixelCount > second.pixelCount) {
      reason = KeeperReason.highestResolution;
    } else {
      reason = KeeperReason.first;
    }

    return KeeperSuggestion(keeper: keeper, reason: reason);
  }

  /// Media IDs in [items] except the suggested keeper.
  Set<int> idsToRemove(List<MediaItem> items) {
    final keeper = call(items);
    return items.where((m) => m.id != keeper.id).map((m) => m.id).toSet();
  }
}
