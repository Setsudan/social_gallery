import 'package:social_gallery/domain/models/media_item.dart';

/// Random or chronological ordering for organize swipe batches.
enum OrganizeQueueOrder { random, chronological }

/// Swipe direction mapped to trash, favorite, keep, or move actions.
enum OrganizeSwipeDirection { left, right, up, down }

/// Restrict organize pool to all media, images only, or videos only.
enum OrganizeMediaType { all, image, video }

extension OrganizeMediaTypeStorage on OrganizeMediaType {
  String get storageValue {
    switch (this) {
      case OrganizeMediaType.all:
        return 'all';
      case OrganizeMediaType.image:
        return 'image';
      case OrganizeMediaType.video:
        return 'video';
    }
  }
}

OrganizeMediaType organizeMediaTypeFromStorage(String value) {
  switch (value) {
    case 'image':
      return OrganizeMediaType.image;
    case 'video':
      return OrganizeMediaType.video;
    default:
      return OrganizeMediaType.all;
  }
}

/// Filter applied when building the organize swipe queue.
class OrganizeFilter {
  const OrganizeFilter({
    this.folderPath,
    this.mediaType = OrganizeMediaType.all,
    this.month,
  });

  final String? folderPath;
  final OrganizeMediaType mediaType;
  final String? month;

  bool get hasActiveFilter =>
      folderPath != null || mediaType != OrganizeMediaType.all || month != null;

  OrganizeFilter copyWith({
    String? folderPath,
    bool clearFolder = false,
    OrganizeMediaType? mediaType,
    String? month,
    bool clearMonth = false,
  }) {
    return OrganizeFilter(
      folderPath: clearFolder ? null : (folderPath ?? this.folderPath),
      mediaType: mediaType ?? this.mediaType,
      month: clearMonth ? null : (month ?? this.month),
    );
  }
}

/// Running totals for the organize session (persisted via [OrganizeRepository]).
class OrganizeStats {
  const OrganizeStats({
    this.processedCount = 0,
    this.deletedCount = 0,
    this.likedCount = 0,
    this.savedBytes = 0,
  });

  final int processedCount;
  final int deletedCount;
  final int likedCount;
  final int savedBytes;

  OrganizeStats copyWith({
    int? processedCount,
    int? deletedCount,
    int? likedCount,
    int? savedBytes,
  }) {
    return OrganizeStats(
      processedCount: processedCount ?? this.processedCount,
      deletedCount: deletedCount ?? this.deletedCount,
      likedCount: likedCount ?? this.likedCount,
      savedBytes: savedBytes ?? this.savedBytes,
    );
  }
}

/// Action type recorded on the organize undo stack.
enum OrganizeUndoType { trash, like, keep, move }

/// One reversible organize action (swipe left/right/up/down).
class OrganizeUndoAction {
  const OrganizeUndoAction({
    required this.type,
    required this.mediaId,
    this.sourceFolderPath,
    this.targetFolderPath,
    this.wasFavorite = false,
  });

  final OrganizeUndoType type;
  final int mediaId;
  final String? sourceFolderPath;
  final String? targetFolderPath;
  final bool wasFavorite;
}

/// In-memory organize session state managed by [OrganizeController].
class OrganizeState {
  const OrganizeState({
    this.queue = const [],
    this.batchDone = 0,
    this.isLoading = true,
    this.pendingTrashCount = 0,
    this.remainingPoolCount = 0,
    this.stats = const OrganizeStats(),
    this.filter = const OrganizeFilter(),
    this.batchSize = 16,
    this.error,
  });

  final List<MediaItem> queue;
  final int batchDone;
  final bool isLoading;
  final int pendingTrashCount;
  final int remainingPoolCount;
  final OrganizeStats stats;
  final OrganizeFilter filter;
  final int batchSize;
  final String? error;

  MediaItem? get currentCard => queue.isNotEmpty ? queue.first : null;

  bool get batchComplete => queue.isEmpty && !isLoading;

  OrganizeState copyWith({
    List<MediaItem>? queue,
    int? batchDone,
    bool? isLoading,
    int? pendingTrashCount,
    int? remainingPoolCount,
    OrganizeStats? stats,
    OrganizeFilter? filter,
    int? batchSize,
    String? error,
    bool clearError = false,
  }) {
    return OrganizeState(
      queue: queue ?? this.queue,
      batchDone: batchDone ?? this.batchDone,
      isLoading: isLoading ?? this.isLoading,
      pendingTrashCount: pendingTrashCount ?? this.pendingTrashCount,
      remainingPoolCount: remainingPoolCount ?? this.remainingPoolCount,
      stats: stats ?? this.stats,
      filter: filter ?? this.filter,
      batchSize: batchSize ?? this.batchSize,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Action performed when the user completes an organize swipe.
enum OrganizeSwipeAction { trash, favorite, keep, move }

extension OrganizeSwipeActionStorage on OrganizeSwipeAction {
  String get storageValue => name;

  static OrganizeSwipeAction fromStorage(String? value) {
    return switch (value) {
      'trash' => OrganizeSwipeAction.trash,
      'favorite' => OrganizeSwipeAction.favorite,
      'keep' => OrganizeSwipeAction.keep,
      'move' => OrganizeSwipeAction.move,
      _ => OrganizeSwipeAction.trash,
    };
  }
}

/// User-configurable mapping from swipe direction to organize action.
///
/// Defaults match historical behavior: left trash, right favorite, up keep,
/// down move (folder strip).
class OrganizeGestureMapping {
  const OrganizeGestureMapping({
    required this.left,
    required this.right,
    required this.up,
    required this.down,
  });

  final OrganizeSwipeAction left;
  final OrganizeSwipeAction right;
  final OrganizeSwipeAction up;
  final OrganizeSwipeAction down;

  static const defaults = OrganizeGestureMapping(
    left: OrganizeSwipeAction.trash,
    right: OrganizeSwipeAction.favorite,
    up: OrganizeSwipeAction.keep,
    down: OrganizeSwipeAction.move,
  );

  /// True when each swipe direction maps to a distinct action.
  bool get isBijective {
    final actions = {left, right, up, down};
    return actions.length == OrganizeSwipeAction.values.length;
  }

  /// Returns [mapping] when bijective, otherwise [defaults].
  static OrganizeGestureMapping ensureBijective(
    OrganizeGestureMapping mapping,
  ) {
    return mapping.isBijective ? mapping : defaults;
  }

  OrganizeSwipeAction actionFor(OrganizeSwipeDirection direction) {
    return switch (direction) {
      OrganizeSwipeDirection.left => left,
      OrganizeSwipeDirection.right => right,
      OrganizeSwipeDirection.up => up,
      OrganizeSwipeDirection.down => down,
    };
  }

  OrganizeSwipeDirection? directionFor(OrganizeSwipeAction action) {
    if (left == action) return OrganizeSwipeDirection.left;
    if (right == action) return OrganizeSwipeDirection.right;
    if (up == action) return OrganizeSwipeDirection.up;
    if (down == action) return OrganizeSwipeDirection.down;
    return null;
  }

  OrganizeGestureMapping copyWith({
    OrganizeSwipeAction? left,
    OrganizeSwipeAction? right,
    OrganizeSwipeAction? up,
    OrganizeSwipeAction? down,
  }) {
    return OrganizeGestureMapping(
      left: left ?? this.left,
      right: right ?? this.right,
      up: up ?? this.up,
      down: down ?? this.down,
    );
  }

  /// Remap [direction] to [action], swapping if [action] was already assigned.
  OrganizeGestureMapping remap(
    OrganizeSwipeDirection direction,
    OrganizeSwipeAction action,
  ) {
    final current = actionFor(direction);
    if (current == action) return this;

    var next = copyWith();
    final previousOwner = directionFor(action);
    next = switch (direction) {
      OrganizeSwipeDirection.left => next.copyWith(left: action),
      OrganizeSwipeDirection.right => next.copyWith(right: action),
      OrganizeSwipeDirection.up => next.copyWith(up: action),
      OrganizeSwipeDirection.down => next.copyWith(down: action),
    };
    if (previousOwner != null && previousOwner != direction) {
      next = switch (previousOwner) {
        OrganizeSwipeDirection.left => next.copyWith(left: current),
        OrganizeSwipeDirection.right => next.copyWith(right: current),
        OrganizeSwipeDirection.up => next.copyWith(up: current),
        OrganizeSwipeDirection.down => next.copyWith(down: current),
      };
    }
    return next;
  }

  Map<String, String> toJson() => {
        'left': left.storageValue,
        'right': right.storageValue,
        'up': up.storageValue,
        'down': down.storageValue,
      };

  static OrganizeGestureMapping fromJson(Map<String, dynamic>? json) {
    if (json == null) return defaults;
    return ensureBijective(
      OrganizeGestureMapping(
        left: OrganizeSwipeActionStorage.fromStorage(json['left'] as String?),
        right: OrganizeSwipeActionStorage.fromStorage(json['right'] as String?),
        up: OrganizeSwipeActionStorage.fromStorage(json['up'] as String?),
        down: OrganizeSwipeActionStorage.fromStorage(json['down'] as String?),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OrganizeGestureMapping &&
        other.left == left &&
        other.right == right &&
        other.up == up &&
        other.down == down;
  }

  @override
  int get hashCode => Object.hash(left, right, up, down);
}
