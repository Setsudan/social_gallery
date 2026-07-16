import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_gallery/core/media/filesystem_image_loader.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/data/datasources/photo_manager_datasource.dart';
import 'package:social_gallery/data/local/app_database.dart';
import 'package:social_gallery/data/repositories/media_repository.dart';
import 'package:social_gallery/data/repositories/preferences_repository.dart';
import 'package:social_gallery/domain/models/media_item.dart';

const folderWidgetAndroidName = 'FolderPhotoWidgetProvider';
const favoritesWidgetAndroidName = 'FavoritesPhotoWidgetProvider';
const onThisDayWidgetAndroidName = 'OnThisDayPhotoWidgetProvider';
const organizeGlanceWidgetAndroidName = 'OrganizeGlanceWidgetProvider';

const widgetRefreshTaskName = 'widget_refresh_task';
const widgetRefreshUniqueName = 'widget_refresh_periodic';

enum WidgetPickMode { random, recent }

enum WidgetPhotoSource { folder, favorites, onThisDay }

class FolderWidgetConfig {
  const FolderWidgetConfig({
    required this.widgetId,
    required this.folderPath,
    required this.folderName,
    required this.intervalMinutes,
    required this.refreshOnUnlock,
    required this.pickMode,
  });

  final int widgetId;
  final String folderPath;
  final String folderName;
  final int intervalMinutes;
  final bool refreshOnUnlock;
  final WidgetPickMode pickMode;

  static String _key(int widgetId, String field) =>
      'sg_folder_widget_${widgetId}_$field';

  static Future<FolderWidgetConfig?> load(int widgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_key(widgetId, 'folderPath'));
    if (path == null || path.isEmpty) return null;
    return FolderWidgetConfig(
      widgetId: widgetId,
      folderPath: path,
      folderName: prefs.getString(_key(widgetId, 'folderName')) ?? path,
      intervalMinutes: prefs.getInt(_key(widgetId, 'intervalMinutes')) ?? 30,
      refreshOnUnlock: prefs.getBool(_key(widgetId, 'refreshOnUnlock')) ?? false,
      pickMode: prefs.getString(_key(widgetId, 'pickMode')) == 'recent'
          ? WidgetPickMode.recent
          : WidgetPickMode.random,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(widgetId, 'folderPath'), folderPath);
    await prefs.setString(_key(widgetId, 'folderName'), folderName);
    await prefs.setInt(_key(widgetId, 'intervalMinutes'), intervalMinutes);
    await prefs.setBool(_key(widgetId, 'refreshOnUnlock'), refreshOnUnlock);
    await prefs.setString(
      _key(widgetId, 'pickMode'),
      pickMode == WidgetPickMode.recent ? 'recent' : 'random',
    );
  }
}

/// Updates Android home-screen widgets with cached image files.
class WidgetUpdateService {
  WidgetUpdateService._();

  static bool get isSupported =>
      !kIsWeb && Platform.isAndroid;

  static Future<void> updateAll() async {
    if (!isSupported) return;
    await updateFolderWidgets();
    await updateFavoritesWidget();
    await updateOnThisDayWidget();
    await updateOrganizeGlance();
  }

  static Future<void> updateFolderWidgets() async {
    if (!isSupported) return;
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('sg_folder_widget_'));
    final ids = <int>{};
    for (final key in keys) {
      final parts = key.split('_');
      if (parts.length < 5) continue;
      final id = int.tryParse(parts[3]);
      if (id != null) ids.add(id);
    }
    for (final id in ids) {
      final config = await FolderWidgetConfig.load(id);
      if (config == null) continue;
      await _updatePhotoWidget(
        androidName: folderWidgetAndroidName,
        source: WidgetPhotoSource.folder,
        folderPath: config.folderPath,
        title: config.folderName,
        random: config.pickMode == WidgetPickMode.random,
        imageKey: 'folder_widget_image_$id',
        titleKey: 'folder_widget_title_$id',
        widgetId: id,
      );
    }
  }

  static Future<void> updateFolderWidget(FolderWidgetConfig config) async {
    if (!isSupported) return;
    await config.save();
    await _updatePhotoWidget(
      androidName: folderWidgetAndroidName,
      source: WidgetPhotoSource.folder,
      folderPath: config.folderPath,
      title: config.folderName,
      random: config.pickMode == WidgetPickMode.random,
      imageKey: 'folder_widget_image_${config.widgetId}',
      titleKey: 'folder_widget_title_${config.widgetId}',
      widgetId: config.widgetId,
    );
  }

  static Future<void> updateFavoritesWidget() async {
    if (!isSupported) return;
    await _updatePhotoWidget(
      androidName: favoritesWidgetAndroidName,
      source: WidgetPhotoSource.favorites,
      title: 'Favorites',
      random: true,
      imageKey: 'favorites_widget_image',
      titleKey: 'favorites_widget_title',
    );
  }

  static Future<void> updateOnThisDayWidget() async {
    if (!isSupported) return;
    await _updatePhotoWidget(
      androidName: onThisDayWidgetAndroidName,
      source: WidgetPhotoSource.onThisDay,
      title: 'On this day',
      random: true,
      imageKey: 'on_this_day_widget_image',
      titleKey: 'on_this_day_widget_title',
    );
  }

  static Future<void> updateOrganizeGlance() async {
    if (!isSupported) return;
    final db = AppDatabase();
    try {
      final prefs = PreferencesRepository(await SharedPreferences.getInstance());
      final repo = MediaRepository(db, PhotoManagerDatasource(prefs), prefs);
      final pool = await repo.getOrganizeMediaPool();
      // Approximate unprocessed as home-feed pool size for glance.
      final count = pool.length;
      await HomeWidget.saveWidgetData<String>(
        'organize_glance_count',
        '$count',
      );
      await HomeWidget.saveWidgetData<String>(
        'organize_glance_label',
        'to organize',
      );
      await HomeWidget.updateWidget(
        name: organizeGlanceWidgetAndroidName,
        androidName: organizeGlanceWidgetAndroidName,
      );
    } finally {
      await db.close();
    }
  }

  static Future<void> _updatePhotoWidget({
    required String androidName,
    required WidgetPhotoSource source,
    required String title,
    required bool random,
    required String imageKey,
    required String titleKey,
    String? folderPath,
    int? widgetId,
  }) async {
    final db = AppDatabase();
    try {
      final prefs = PreferencesRepository(await SharedPreferences.getInstance());
      final repo = MediaRepository(db, PhotoManagerDatasource(prefs), prefs);
      MediaItem? item;
      switch (source) {
        case WidgetPhotoSource.folder:
          item = await repo.pickFolderWidgetMedia(
            folderPath ?? '',
            random: random,
          );
        case WidgetPhotoSource.favorites:
          item = await repo.pickFavoriteWidgetMedia(random: random);
        case WidgetPhotoSource.onThisDay:
          item = await repo.pickOnThisDayWidgetMedia(random: random);
      }
      if (item == null) return;

      final imagePath = await _cacheWidgetImage(item, imageKey);
      if (imagePath == null) return;

      await HomeWidget.saveWidgetData<String>(imageKey, imagePath);
      await HomeWidget.saveWidgetData<String>(titleKey, title);
      if (widgetId != null) {
        await HomeWidget.saveWidgetData<String>(
          'folder_widget_id_$widgetId',
          '$widgetId',
        );
      }
      await HomeWidget.updateWidget(
        name: androidName,
        androidName: androidName,
      );
    } finally {
      await db.close();
    }
  }

  static Future<String?> _cacheWidgetImage(
    MediaItem item,
    String cacheKey,
  ) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final widgetDir = Directory(p.join(dir.path, 'widgets'));
      if (!widgetDir.existsSync()) {
        await widgetDir.create(recursive: true);
      }
      final out = File(p.join(widgetDir.path, '$cacheKey.jpg'));

      if (usesFilesystemGallery) {
        final bytes = await readFilesystemThumbnailBytes(item.uri);
        if (bytes == null || bytes.isEmpty) return null;
        await out.writeAsBytes(bytes);
        return out.path;
      }

      final entity = await AssetEntity.fromId(item.uri);
      if (entity == null) return null;
      final data = await entity.thumbnailDataWithSize(
        const ThumbnailSize(800, 800),
      );
      if (data == null || data.isEmpty) return null;
      await out.writeAsBytes(data);
      return out.path;
    } catch (_) {
      return null;
    }
  }
}
