import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';

final homeStoriesProvider = FutureProvider<List<FolderWithStories>>((ref) {
  return ref.watch(mediaRepositoryProvider).getFoldersWithStories();
});
