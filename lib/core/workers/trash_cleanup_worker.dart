import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/widgets/widget_update_service.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:workmanager/workmanager.dart';

const trashCleanupTaskName = 'trash_cleanup_task';
const trashCleanupUniqueName = 'trash_cleanup_periodic';

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == trashCleanupTaskName) {
        final prefs = await SharedPreferences.getInstance();
        final preferences = PreferencesRepository(prefs);
        final db = AppDatabase();
        final repo = MediaRepository(
          db,
          PhotoManagerDatasource(preferences),
          preferences,
        );
        await repo.cleanupExpiredTrash(preferences.trashRetentionDays);
        await db.close();
        return true;
      }
      if (task == widgetRefreshTaskName ||
          task == Workmanager.iOSBackgroundTask) {
        await WidgetUpdateService.updateAll();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  });
}

/// Legacy alias used by older call sites.
@pragma('vm:entry-point')
void trashCleanupCallbackDispatcher() => backgroundCallbackDispatcher();

Future<void> registerTrashCleanupWork() async {
  await Workmanager().initialize(backgroundCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    trashCleanupUniqueName,
    trashCleanupTaskName,
    frequency: const Duration(hours: 24),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}

Future<void> registerWidgetRefreshWork() async {
  if (!WidgetUpdateService.isSupported) return;
  await Workmanager().initialize(backgroundCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    widgetRefreshUniqueName,
    widgetRefreshTaskName,
    // Android minimum periodic interval is typically 15 minutes.
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );
}
