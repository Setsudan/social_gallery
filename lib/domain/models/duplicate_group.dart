import 'media_item.dart';

class DuplicateGroup {
  const DuplicateGroup({
    required this.size,
    required this.width,
    required this.height,
    required this.items,
  });

  final int size;
  final int? width;
  final int? height;
  final List<MediaItem> items;

  int get count => items.length;

  String get key => '${size}_${width ?? -1}_${height ?? -1}';
}
