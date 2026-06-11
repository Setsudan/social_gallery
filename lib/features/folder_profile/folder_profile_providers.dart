import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/folder_info.dart';

final folderProvider = StreamProvider.family<FolderInfo?, String>((ref, path) {
  return ref.watch(folderRepositoryProvider).watchFolder(path);
});
