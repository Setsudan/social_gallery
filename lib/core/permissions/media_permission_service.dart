import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

enum MediaPermissionState { checking, granted, denied, limited }

class MediaPermissionService {
  Future<MediaPermissionState> check() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return MediaPermissionState.denied;
    }
    final state = await PhotoManager.requestPermissionExtend();
    return _mapState(state);
  }

  Future<MediaPermissionState> request() async {
    if (Platform.isAndroid) {
      await [Permission.photos, Permission.videos].request();
    }
    final state = await PhotoManager.requestPermissionExtend();
    return _mapState(state);
  }

  MediaPermissionState _mapState(PermissionState state) {
    if (state.isAuth) {
      return state == PermissionState.limited
          ? MediaPermissionState.limited
          : MediaPermissionState.granted;
    }
    return MediaPermissionState.denied;
  }
}
