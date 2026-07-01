import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/folder_with_stories.dart';

/// Folders with new media in the last 24h for the home stories row.
final homeStoriesProvider = FutureProvider<List<FolderWithStories>>((ref) {
  return ref.watch(mediaRepositoryProvider).getFoldersWithStories();
});
