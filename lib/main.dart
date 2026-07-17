import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/app/app.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/widgets/widget_update_service.dart';
import 'package:social_gallery/core/workers/trash_cleanup_worker.dart';
import 'package:window_manager/window_manager.dart';

/// Application entry: SharedPreferences override, background workers, ProviderScope.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep more decoded thumbs while flinging / reversing grids.
  PaintingBinding.instance.imageCache.maximumSize = 400;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 160 << 20;
  if (usesFilesystemGallery) {
    await windowManager.ensureInitialized();
  }
  final prefs = await SharedPreferences.getInstance();

  try {
    await registerTrashCleanupWork();
  } catch (e) {
    debugPrint('Trash cleanup scheduling failed: $e');
  }

  try {
    await registerWidgetRefreshWork();
    if (WidgetUpdateService.isSupported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ignore: unawaited_futures
        WidgetUpdateService.updateAll();
      });
    }
  } catch (e) {
    debugPrint('Widget refresh scheduling failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SocialGalleryApp(),
    ),
  );
}
