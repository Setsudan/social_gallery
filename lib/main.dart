import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/app/app.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/workers/trash_cleanup_worker.dart';

/// Application entry: SharedPreferences override, background workers, ProviderScope.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  try {
    await registerTrashCleanupWork();
  } catch (e) {
    debugPrint('Trash cleanup scheduling failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SocialGalleryApp(),
    ),
  );
}
