import 'dart:io';

import 'package:flutter/foundation.dart';

/// Desktop platforms that scan a user-chosen folder instead of the system photo library.
bool get usesFilesystemGallery =>
    !kIsWeb &&
    (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
