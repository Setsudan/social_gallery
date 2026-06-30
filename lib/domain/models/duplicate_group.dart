import 'media_item.dart';

/// Near-identical photos clustered by [FindDuplicateGroups] for review UI.
class DuplicateGroup {
  const DuplicateGroup({
    required this.id,
    required this.items,
  });

  final String id;
  final List<MediaItem> items;

  int get count => items.length;

  String get key => id;
}
