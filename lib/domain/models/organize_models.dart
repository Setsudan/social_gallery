import 'package:social_gallery/domain/models/media_item.dart';

enum OrganizeQueueOrder { random, chronological }

enum OrganizeSwipeDirection { left, right, up, down }

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

enum OrganizeUndoType { trash, like, keep, move }

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
    this.showFolderDrop = false,
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
  final bool showFolderDrop;
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
    bool? showFolderDrop,
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
      showFolderDrop: showFolderDrop ?? this.showFolderDrop,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
