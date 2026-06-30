import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/cache/cache_service.dart';
import 'package:social_gallery/core/gallery/desktop_gallery_root_picker.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/core/theme/accent_presets.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/shared/widgets/motion/animation_speed_preview.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_settings_tile.dart';
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl = 'https://example.com/privacy';

const _animationSpeedSteps = [0.001, 0.5, 1.0, 2.0];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _cacheBytes = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
    _loadVersion();
  }

  Future<void> _loadCacheSize() async {
    final bytes = await ref.read(cacheServiceProvider).getCacheSizeBytes();
    if (mounted) setState(() => _cacheBytes = bytes);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache'),
        content: Text(
          'Clear ${CacheService.formatBytes(_cacheBytes)} of cached thumbnails and temp files?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cacheServiceProvider).clearCache();
      await _loadCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
      }
    }
  }

  String _themeLabel(AppThemeVariant variant) {
    return appThemeVariantLabel(variant);
  }

  String _fontLabel(double factor) {
    if (factor < 0.9) return 'Small';
    if (factor < 1.1) return 'Normal';
    if (factor < 1.3) return 'Large';
    return 'Extra large';
  }

  String _animationLabel(double speed) {
    if (speed <= 0.01) return 'Instant';
    if (speed < 0.75) return 'Fast';
    if (speed < 1.5) return 'Normal';
    return 'Slow';
  }

  int _animationSpeedIndex(double speed) {
    var closestIndex = 0;
    var closestDistance = double.infinity;
    for (var i = 0; i < _animationSpeedSteps.length; i++) {
      final distance = (speed - _animationSpeedSteps[i]).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  double _animationSpeedFromIndex(int index) {
    return _animationSpeedSteps[index.clamp(0, _animationSpeedSteps.length - 1)];
  }

  Future<void> _pickTheme(AppThemeVariant current) async {
    final picked = await showOneUiSettingsPicker<AppThemeVariant>(
      context: context,
      title: 'Theme',
      selected: current,
      options: const [
        OneUiPickerOption(
          value: AppThemeVariant.system,
          label: 'System default',
        ),
        OneUiPickerOption(value: AppThemeVariant.light, label: 'Light'),
        OneUiPickerOption(value: AppThemeVariant.solar, label: 'Solar'),
        OneUiPickerOption(value: AppThemeVariant.dark, label: 'Dark'),
        OneUiPickerOption(
          value: AppThemeVariant.darkOled,
          label: 'Dark OLED',
        ),
      ],
    );
    if (picked != null && picked != current) {
      AppHaptics.medium();
      ref.read(settingsProvider.notifier).setAppTheme(picked);
    }
  }

  Future<void> _pickAccentColor(Color current) async {
    await showOneUiSettingsSheet<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.sm,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Accent color', style: theme.textTheme.titleLarge),
              const SizedBox(height: OneUiSpacing.sm),
              Text(
                'Choose the accent used for buttons, links, and highlights.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: OneUiSpacing.lg),
              Wrap(
                spacing: OneUiSpacing.md,
                runSpacing: OneUiSpacing.md,
                children: [
                  for (final preset in AccentPresets.all)
                    _AccentSwatch(
                      preset: preset,
                      selected:
                          preset.color.toARGB32() == current.toARGB32(),
                      onTap: () {
                        AppHaptics.medium();
                        ref
                            .read(settingsProvider.notifier)
                            .setAccentColor(preset.color);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFontSize() async {
    await showOneUiSettingsSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final fontSizeFactor = ref.watch(
              settingsProvider.select((s) => s.fontSizeFactor),
            );
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.sm,
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Font size', style: theme.textTheme.titleLarge),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    'Scale text across the app.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: OneUiSpacing.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.format_size_outlined,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: Slider(
                          value: fontSizeFactor,
                          min: 0.8,
                          max: 1.4,
                          divisions: 3,
                          label: _fontLabel(fontSizeFactor),
                          onChanged: (value) {
                            AppHaptics.selection();
                            ref
                                .read(settingsProvider.notifier)
                                .setFontSizeFactor(value);
                          },
                        ),
                      ),
                      Icon(
                        Icons.format_size_outlined,
                        size: 26,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      _fontLabel(fontSizeFactor),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAnimationSpeed() async {
    await showOneUiSettingsSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final animationSpeed = ref.watch(
              settingsProvider.select((s) => s.animationSpeed),
            );
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.sm,
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Animation speed', style: theme.textTheme.titleLarge),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    'Preview how fast transitions feel across the app.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: OneUiSpacing.lg),
                  AnimationSpeedPreview(speedFactor: animationSpeed),
                  const SizedBox(height: OneUiSpacing.lg),
                  Row(
                    children: [
                      Icon(
                        Icons.speed_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: Slider(
                          value: _animationSpeedIndex(animationSpeed).toDouble(),
                          min: 0,
                          max: (_animationSpeedSteps.length - 1).toDouble(),
                          divisions: _animationSpeedSteps.length - 1,
                          label: _animationLabel(animationSpeed),
                          onChanged: (value) {
                            AppHaptics.selection();
                            ref
                                .read(settingsProvider.notifier)
                                .setAnimationSpeed(
                                  _animationSpeedFromIndex(value.round()),
                                );
                          },
                        ),
                      ),
                      Icon(
                        Icons.motion_photos_auto_outlined,
                        size: 22,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  Center(
                    child: Text(
                      _animationLabel(animationSpeed),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickTrashRetention() async {
    await showOneUiSettingsSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final days = ref.watch(
              settingsProvider.select((s) => s.trashRetentionDays),
            );
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.sm,
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Trash retention', style: theme.textTheme.titleLarge),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    'Items in trash are permanently removed after this period.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: OneUiSpacing.lg),
                  Slider(
                    value: days.toDouble(),
                    min: 1,
                    max: 90,
                    divisions: 89,
                    label: '$days days',
                    onChanged: (value) {
                      AppHaptics.selection();
                      ref
                          .read(settingsProvider.notifier)
                          .setTrashRetentionDays(value.round());
                    },
                  ),
                  Center(
                    child: Text(
                      '$days days',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickCacheLimit() async {
    await showOneUiSettingsSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final limitMb = ref.watch(
              settingsProvider.select((s) => s.cacheSizeLimitMb),
            );
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.sm,
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Cache size limit', style: theme.textTheme.titleLarge),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    'Maximum storage used by thumbnails and temp files.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: OneUiSpacing.lg),
                  Slider(
                    value: limitMb.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: '$limitMb MB',
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setCacheSizeLimitMb(value.round());
                    },
                  ),
                  Center(
                    child: Text(
                      '$limitMb MB',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickOrganizeBatchSize() async {
    await showOneUiSettingsSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final batchSize = ref.watch(organizeBatchSizeProvider);
            final theme = Theme.of(context);
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.sm,
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Batch size', style: theme.textTheme.titleLarge),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    'Number of photos per organize session.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: OneUiSpacing.lg),
                  Slider(
                    value: batchSize.toDouble(),
                    min: 10,
                    max: 30,
                    divisions: 20,
                    label: '$batchSize',
                    onChanged: (value) {
                      AppHaptics.selection();
                      final size = value.round();
                      ref.read(organizeBatchSizeProvider.notifier).state = size;
                      ref.read(organizeRepositoryProvider).setBatchSize(size);
                    },
                  ),
                  Center(
                    child: Text(
                      '$batchSize photos',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickGalleryRoot() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    final currentPath = prefs.desktopGalleryRootPath;

    try {
      final path = await pickDesktopGalleryRootFolder();
      if (path == null || path.isEmpty) return;

      if (path == currentPath) return;

      final saved = await saveDesktopGalleryRootPath(prefs, path);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not use that folder')),
        );
        return;
      }

      setState(() {});
      unawaited(ref.read(gallerySyncProvider.notifier).run(force: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gallery root updated. Rescanning library.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select folder: $e')),
      );
    }
  }

  Future<void> _pickQueueOrder(OrganizeQueueOrder current) async {
    final picked = await showOneUiSettingsPicker<OrganizeQueueOrder>(
      context: context,
      title: 'Queue order',
      selected: current,
      options: const [
        OneUiPickerOption(value: OrganizeQueueOrder.random, label: 'Random'),
        OneUiPickerOption(
          value: OrganizeQueueOrder.chronological,
          label: 'Chronological',
        ),
      ],
    );
    if (picked != null && picked != current) {
      ref.read(organizeRepositoryProvider).setQueueOrder(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final repo = ref.watch(organizeRepositoryProvider);
    final batchSize = ref.watch(organizeBatchSizeProvider);
    final galleryRootPath = usesFilesystemGallery
        ? ref.watch(preferencesRepositoryProvider).desktopGalleryRootPath
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.light();
            context.pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: OneUiSpacing.xl),
        children: [
          if (kDebugMode) ...[
            const _DebugBuildWarningCard(),
            const SizedBox(height: OneUiSpacing.sectionGap),
          ],
          OneUiSettingsSection(
            title: 'Appearance',
            headerPadding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.md,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
            ),
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.display,
                title: 'Theme',
                value: _themeLabel(settings.appTheme),
                onTap: () => _pickTheme(settings.appTheme),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.palette,
                title: 'Accent color',
                value: AccentPresets.labelFor(settings.accentColor),
                showDivider: true,
                onTap: () => _pickAccentColor(settings.accentColor),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.text,
                title: 'Font size',
                value: _fontLabel(settings.fontSizeFactor),
                showDivider: true,
                onTap: _pickFontSize,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.motion,
                title: 'Animation speed',
                value: _animationLabel(settings.animationSpeed),
                showDivider: true,
                onTap: _pickAnimationSpeed,
              ),
            ],
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSettingsSection(
            title: 'Gallery',
            children: [
              if (usesFilesystemGallery)
                OneUiSettingsTile(
                  icon: OneUiSettingsIcon.folder,
                  title: 'Gallery root folder',
                  subtitle: galleryRootPath?.isNotEmpty == true
                      ? galleryRootPath
                      : 'Choose a folder to scan for photos and videos',
                  value: galleryRootDisplayValue(galleryRootPath),
                  onTap: _pickGalleryRoot,
                ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.gallery,
                title: 'Gallery view mode',
                subtitle: 'Pinch-zoom gallery tab instead of Home and Explore',
                showDivider: usesFilesystemGallery,
                trailing: Switch.adaptive(
                  value: settings.galleryViewMode,
                  onChanged: (value) {
                    AppHaptics.medium();
                    ref.read(settingsProvider.notifier).setGalleryViewMode(value);
                  },
                ),
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSettingsSection(
            title: 'Content',
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.folder,
                title: 'Manage content',
                subtitle: 'Folders, home feed, and visibility',
                onTap: () {
                  AppHaptics.light();
                  context.push('/folder_management');
                },
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.travel,
                title: 'Travel mode',
                subtitle: 'Trips and date-range organization',
                showDivider: true,
                onTap: () {
                  AppHaptics.light();
                  context.push('/travel_mode');
                },
              ),
            ],
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSettingsSection(
            title: 'Organize',
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.organize,
                title: 'Batch size',
                value: '$batchSize',
                onTap: _pickOrganizeBatchSize,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.organize,
                title: 'Queue order',
                value: repo.queueOrder == OrganizeQueueOrder.random
                    ? 'Random'
                    : 'Chronological',
                showDivider: true,
                onTap: () => _pickQueueOrder(repo.queueOrder),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.organize,
                title: 'Release kept photos',
                subtitle: 'Return processed photos to the organize queue',
                showDivider: true,
                onTap: () async {
                  AppHaptics.light();
                  await repo.clearProcessed();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Released kept photos')),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSettingsSection(
            title: 'Storage',
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.trash,
                title: 'Trash retention',
                value: '${settings.trashRetentionDays} days',
                onTap: _pickTrashRetention,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.trash,
                title: 'Deleted items',
                subtitle: 'View, restore, or empty trash',
                showDivider: true,
                onTap: () {
                  AppHaptics.light();
                  context.push('/trash');
                },
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.storage,
                title: 'Cache',
                value: CacheService.formatBytes(_cacheBytes),
                showDivider: true,
                onTap: _cacheBytes > 0 ? _clearCache : null,
                showChevron: _cacheBytes > 0,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.storage,
                title: 'Cache size limit',
                value: '${settings.cacheSizeLimitMb} MB',
                showDivider: true,
                onTap: _pickCacheLimit,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.storage,
                title: 'Auto-clear on close',
                subtitle: 'Clear cache when the app is closed',
                showDivider: true,
                trailing: Switch.adaptive(
                  value: settings.autoClearCacheOnClose,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setAutoClearCacheOnClose(value);
                  },
                ),
                showChevron: false,
              ),
            ],
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSettingsSection(
            title: 'About',
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.info,
                title: 'Version',
                value: _appVersion.isEmpty ? '...' : _appVersion,
                showChevron: false,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.privacy,
                title: 'Privacy policy',
                showDivider: true,
                onTap: () => launchUrl(
                  Uri.parse(_privacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.license,
                title: 'Open-source licenses',
                showDivider: true,
                onTap: () => showLicensePage(context: context),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.share,
                title: 'Share app',
                showDivider: true,
                onTap: () => Share.share(
                  'Check out Social Gallery - a local-first photo gallery.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebugBuildWarningCard extends StatelessWidget {
  const _DebugBuildWarningCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warningColor = isDark
        ? const Color(0xFFF9A825)
        : const Color(0xFFE65100);
    final backgroundColor = isDark
        ? warningColor.withValues(alpha: 0.18)
        : const Color(0xFFFFF8E1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OneUiSpacing.pageHorizontal,
        OneUiSpacing.md,
        OneUiSpacing.pageHorizontal,
        0,
      ),
      child: Card(
        color: backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(OneUiSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 22,
                color: warningColor,
              ),
              const SizedBox(width: OneUiSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug build',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: OneUiSpacing.xs),
                    Text(
                      'This is not a production build and may contain errors.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AccentPreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: preset.label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: preset.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? theme.colorScheme.onSurface : Colors.transparent,
              width: 2,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}
