import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _clipboardChannel = MethodChannel('one.launay.social_gallery/clipboard');

/// Copies an image file to the system clipboard (Android via FileProvider URI).
Future<bool> copyImageFileToClipboard(File file) async {
  if (!Platform.isAndroid) return false;
  try {
    final ok = await _clipboardChannel.invokeMethod<bool>(
      'copyImageFile',
      <String, dynamic>{'path': file.path},
    );
    return ok == true;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

/// Desktop/iOS: not supported for image clipboard in this app.
bool get supportsImageClipboard =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
