import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';

Future<String?> pickDesktopGalleryRootFolder() async {
  if (!usesFilesystemGallery) return null;
  return FilePicker.platform.getDirectoryPath(
    dialogTitle: 'Select Root Gallery Folder',
  );
}

Future<bool> saveDesktopGalleryRootPath(
  PreferencesRepository prefs,
  String path,
) async {
  if (path.isEmpty || !Directory(path).existsSync()) return false;
  await prefs.setDesktopGalleryRootPath(path);
  return true;
}

String galleryRootDisplayValue(String? path) {
  if (path == null || path.isEmpty) return 'Not set';
  final segments = path.split(RegExp(r'[/\\]'));
  if (segments.length <= 2) return path;
  return '.../${segments.sublist(segments.length - 2).join('/')}';
}
