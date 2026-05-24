import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Android 11+ "All files access" for move/delete across albums.
///
/// iOS has no equivalent to [MANAGE_EXTERNAL_STORAGE]; library changes use
/// PhotoKit within the granted photo library scope.
class StorageAccessService {
  Future<bool> hasAllFilesAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }
    return Permission.manageExternalStorage.isGranted;
  }

  Future<bool> requestAllFilesAccess() async {
    if (!Platform.isAndroid) {
      return true;
    }
    if (await hasAllFilesAccess()) {
      return true;
    }
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  Future<void> openAllFilesSettings() => openAppSettings();
}
