import 'dart:io';

import 'package:path_provider/path_provider.dart';

class CacheService {
  Future<int> getCacheSizeBytes() async {
    var total = 0;
    final tempDir = await getTemporaryDirectory();
    total += await _dirSize(tempDir);

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final cacheDir = await getApplicationCacheDirectory();
        total += await _dirSize(cacheDir);
      } catch (_) {}
    }
    return total;
  }

  Future<void> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    await _clearDir(tempDir);
    try {
      final cacheDir = await getApplicationCacheDirectory();
      await _clearDir(cacheDir);
    } catch (_) {}
  }

  Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<void> _clearDir(Directory dir) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      try {
        if (entity is File) {
          await entity.delete();
        } else if (entity is Directory) {
          await entity.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
