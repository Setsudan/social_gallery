class MediaItem {
  const MediaItem({
    required this.id,
    required this.uri,
    required this.displayName,
    required this.folderName,
    required this.folderPath,
    required this.dateAdded,
    required this.dateModified,
    this.dateTaken,
    required this.size,
    required this.mimeType,
    this.width,
    this.height,
    this.isFavorite = false,
    this.videoDuration,
  });

  final int id;
  final String uri;
  final String displayName;
  final String folderName;
  final String folderPath;
  final int dateAdded;
  final int dateModified;
  final int? dateTaken;
  final int size;
  final String mimeType;
  final int? width;
  final int? height;
  final bool isFavorite;
  final int? videoDuration;

  bool get isVideo => mimeType.startsWith('video/');

  int get sortDate => dateTaken ?? dateModified;

  int get pixelCount => (width ?? 0) * (height ?? 0);

  MediaItem copyWith({bool? isFavorite}) {
    return MediaItem(
      id: id,
      uri: uri,
      displayName: displayName,
      folderName: folderName,
      folderPath: folderPath,
      dateAdded: dateAdded,
      dateModified: dateModified,
      dateTaken: dateTaken,
      size: size,
      mimeType: mimeType,
      width: width,
      height: height,
      isFavorite: isFavorite ?? this.isFavorite,
      videoDuration: videoDuration,
    );
  }
}
