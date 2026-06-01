import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:workmanager/workmanager.dart';

const trashCleanupTaskName = 'trash_cleanup_task';
const trashCleanupUniqueName = 'trash_cleanup_periodic';

@pragma('vm:entry-point')
void trashCleanupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != trashCleanupTaskName) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferences = PreferencesRepository(prefs);
      final db = AppDatabase();
      final repo = MediaRepository(db, PhotoManagerDatasource(preferences), preferences);
      await repo.cleanupExpiredTrash(preferences.trashRetentionDays);
      await db.close();
      return true;
    } catch (_) {
      return false;
    }
  });
}

Future<void> registerTrashCleanupWork() async {
  await Workmanager().initialize(trashCleanupCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    trashCleanupUniqueName,
    trashCleanupTaskName,
    frequency: const Duration(hours: 24),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}
