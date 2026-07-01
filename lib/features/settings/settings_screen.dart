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
import 'package:social_gallery/core/l10n/app_locale_preference.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/l10n/l10n_labels.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/core/theme/accent_presets.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/desktop_gallery_grid_size.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/features/settings/backup_settings_section.dart';
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
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialogClearCacheTitle),
        content: Text(l10n.dialogClearCacheMessage(_cacheBytes)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.actionClear),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(cacheServiceProvider).clearCache();
      await _loadCacheSize();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.snackbarCacheCleared)),
        );
      }
    }
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

  Future<void> _pickLanguage(AppLocalePreference current) async {
    final l10n = context.l10n;
    final picked = await showOneUiSettingsPicker<AppLocalePreference>(
      context: context,
      title: l10n.settingsLanguage,
      selected: current,
      options: [
        for (final preference in AppLocalePreference.values)
          OneUiPickerOption(
            value: preference,
            label: appLocalePreferenceLabel(l10n, preference),
          ),
      ],
    );
    if (picked != null && picked != current) {
      AppHaptics.medium();
      ref.read(settingsProvider.notifier).setLocalePreference(picked);
    }
  }

  Future<void> _pickTheme(AppThemeVariant current) async {
    final l10n = context.l10n;
    final picked = await showOneUiSettingsPicker<AppThemeVariant>(
      context: context,
      title: l10n.settingsTheme,
      selected: current,
      options: [
        OneUiPickerOption(
          value: AppThemeVariant.system,
          label: appThemeVariantLabel(l10n, AppThemeVariant.system),
        ),
        OneUiPickerOption(
          value: AppThemeVariant.light,
          label: appThemeVariantLabel(l10n, AppThemeVariant.light),
        ),
        OneUiPickerOption(
          value: AppThemeVariant.solar,
          label: appThemeVariantLabel(l10n, AppThemeVariant.solar),
        ),
        OneUiPickerOption(
          value: AppThemeVariant.dark,
          label: appThemeVariantLabel(l10n, AppThemeVariant.dark),
        ),
        OneUiPickerOption(
          value: AppThemeVariant.darkOled,
          label: appThemeVariantLabel(l10n, AppThemeVariant.darkOled),
        ),
      ],
    );
    if (picked != null && picked != current) {
      AppHaptics.medium();
      ref.read(settingsProvider.notifier).setAppTheme(picked);
    }
  }

  Future<void> _pickAccentColor(Color current) async {
    final l10n = context.l10n;
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
              Text(l10n.settingsAccentColor, style: theme.textTheme.titleLarge),
              const SizedBox(height: OneUiSpacing.sm),
              Text(
                l10n.settingsAccentColorDescription,
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

  Future<void> _pickDesktopGalleryGridSize(
    DesktopGalleryGridSize current,
  ) async {
    final l10n = context.l10n;
    final picked = await showOneUiSettingsPicker<DesktopGalleryGridSize>(
      context: context,
      title: l10n.settingsGalleryGridSize,
      selected: current,
      options: [
        for (final size in DesktopGalleryGridSize.values)
          OneUiPickerOption(
            value: size,
            label: desktopGalleryGridSizeLabel(l10n, size),
            subtitle: desktopGalleryGridSizeSubtitle(l10n, size),
          ),
      ],
    );
    if (picked != null && picked != current) {
      AppHaptics.medium();
      ref.read(settingsProvider.notifier).setDesktopGalleryGridSize(picked);
    }
  }

  Future<void> _pickFontSize() async {
    final l10n = context.l10n;
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
                  Text(l10n.settingsFontSize, style: theme.textTheme.titleLarge),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    l10n.settingsFontSizeDescription,
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
                          label: fontSizeLabel(l10n, fontSizeFactor),
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
                      fontSizeLabel(l10n, fontSizeFactor),
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
    final l10n = context.l10n;
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
                  Text(
                    l10n.settingsAnimationSpeed,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    l10n.settingsAnimationSpeedDescription,
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
                          label: animationSpeedLabel(l10n, animationSpeed),
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
                      animationSpeedLabel(l10n, animationSpeed),
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
    final l10n = context.l10n;
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
                  Text(
                    l10n.settingsTrashRetention,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    l10n.settingsTrashRetentionDescription,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: OneUiSpacing.lg),
                  Slider(
                    value: days.toDouble(),
                    min: 1,
                    max: 90,
                    divisions: 89,
                    label: l10n.settingsTrashRetentionDays(days),
                    onChanged: (value) {
                      AppHaptics.selection();
                      ref
                          .read(settingsProvider.notifier)
                          .setTrashRetentionDays(value.round());
                    },
                  ),
                  Center(
                    child: Text(
                      l10n.settingsTrashRetentionDays(days),
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
    final l10n = context.l10n;
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
                  Text(
                    l10n.settingsCacheSizeLimit,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    l10n.settingsCacheSizeLimitDescription,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: OneUiSpacing.lg),
                  Slider(
                    value: limitMb.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: l10n.settingsCacheSizeLimitValue(limitMb),
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setCacheSizeLimitMb(value.round());
                    },
                  ),
                  Center(
                    child: Text(
                      l10n.settingsCacheSizeLimitValue(limitMb),
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
    final l10n = context.l10n;
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
                  Text(l10n.settingsBatchSize, style: theme.textTheme.titleLarge),
                  const SizedBox(height: OneUiSpacing.sm),
                  Text(
                    l10n.settingsBatchSizeDescription,
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
                      l10n.settingsBatchSizeValue(batchSize),
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
    final l10n = context.l10n;
    final prefs = ref.read(preferencesRepositoryProvider);
    final currentPath = prefs.desktopGalleryRootPath;

    try {
      final path = await pickDesktopGalleryRootFolder(l10n);
      if (path == null || path.isEmpty) return;

      if (path == currentPath) return;

      final saved = await saveDesktopGalleryRootPath(prefs, path);
      if (!mounted) return;

      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorCouldNotUseFolder)),
        );
        return;
      }

      setState(() {});
      unawaited(ref.read(gallerySyncProvider.notifier).run(force: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackbarGalleryRootUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorFailedToSelectFolder('$e'))),
      );
    }
  }

  Future<void> _pickQueueOrder(OrganizeQueueOrder current) async {
    final l10n = context.l10n;
    final picked = await showOneUiSettingsPicker<OrganizeQueueOrder>(
      context: context,
      title: l10n.settingsQueueOrder,
      selected: current,
      options: [
        OneUiPickerOption(
          value: OrganizeQueueOrder.random,
          label: l10n.queueOrderRandom,
        ),
        OneUiPickerOption(
          value: OrganizeQueueOrder.chronological,
          label: l10n.queueOrderChronological,
        ),
      ],
    );
    if (picked != null && picked != current) {
      ref.read(organizeRepositoryProvider).setQueueOrder(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            title: l10n.settingsSectionAppearance,
            headerPadding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.md,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
            ),
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.language,
                title: l10n.settingsLanguage,
                value: appLocalePreferenceLabel(l10n, settings.localePreference),
                onTap: () => _pickLanguage(settings.localePreference),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.display,
                title: l10n.settingsTheme,
                value: appThemeVariantLabel(l10n, settings.appTheme),
                showDivider: true,
                onTap: () => _pickTheme(settings.appTheme),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.palette,
                title: l10n.settingsAccentColor,
                value: accentPresetLabel(l10n, settings.accentColor),
                showDivider: true,
                onTap: () => _pickAccentColor(settings.accentColor),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.text,
                title: l10n.settingsFontSize,
                value: fontSizeLabel(l10n, settings.fontSizeFactor),
                showDivider: true,
                onTap: _pickFontSize,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.motion,
                title: l10n.settingsAnimationSpeed,
                value: animationSpeedLabel(l10n, settings.animationSpeed),
                showDivider: true,
                onTap: _pickAnimationSpeed,
              ),
            ],
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSettingsSection(
            title: l10n.settingsSectionGallery,
            children: [
              if (usesFilesystemGallery)
                OneUiSettingsTile(
                  icon: OneUiSettingsIcon.folder,
                  title: l10n.settingsGalleryRootFolder,
                  subtitle: galleryRootPath?.isNotEmpty == true
                      ? galleryRootPath
                      : l10n.settingsGalleryRootFolderEmptySubtitle,
                  value: galleryRootDisplayValue(galleryRootPath, l10n),
                  onTap: _pickGalleryRoot,
                ),
              if (usesFilesystemGallery)
                OneUiSettingsTile(
                  icon: OneUiSettingsIcon.gallery,
                  title: l10n.settingsGalleryGridSize,
                  subtitle: desktopGalleryGridSizeSubtitle(
                    l10n,
                    settings.desktopGalleryGridSize,
                  ),
                  value: desktopGalleryGridSizeLabel(
                    l10n,
                    settings.desktopGalleryGridSize,
                  ),
                  showDivider: true,
                  onTap: () => _pickDesktopGalleryGridSize(
                    settings.desktopGalleryGridSize,
                  ),
                ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.gallery,
                title: l10n.settingsGalleryViewMode,
                subtitle: l10n.settingsGalleryViewModeSubtitle,
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
          const BackupSettingsSection(),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSettingsSection(
            title: l10n.settingsSectionContent,
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.folder,
                title: l10n.settingsManageContent,
                subtitle: l10n.settingsManageContentSubtitle,
                onTap: () {
                  AppHaptics.light();
                  context.push('/folder_management');
                },
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.travel,
                title: l10n.settingsTravelMode,
                subtitle: l10n.settingsTravelModeSubtitle,
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
            title: l10n.settingsSectionOrganize,
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.organize,
                title: l10n.settingsBatchSize,
                value: '$batchSize',
                onTap: _pickOrganizeBatchSize,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.organize,
                title: l10n.settingsQueueOrder,
                value: repo.queueOrder == OrganizeQueueOrder.random
                    ? l10n.queueOrderRandom
                    : l10n.queueOrderChronological,
                showDivider: true,
                onTap: () => _pickQueueOrder(repo.queueOrder),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.organize,
                title: l10n.settingsReleaseKeptPhotos,
                subtitle: l10n.settingsReleaseKeptPhotosSubtitle,
                showDivider: true,
                onTap: () async {
                  AppHaptics.light();
                  await repo.clearProcessed();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.snackbarReleasedKeptPhotos)),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiSettingsSection(
            title: l10n.settingsSectionStorage,
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.trash,
                title: l10n.settingsTrashRetention,
                value: l10n.settingsTrashRetentionDays(settings.trashRetentionDays),
                onTap: _pickTrashRetention,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.trash,
                title: l10n.settingsDeletedItems,
                subtitle: l10n.settingsDeletedItemsSubtitle,
                showDivider: true,
                onTap: () {
                  AppHaptics.light();
                  context.push('/trash');
                },
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.storage,
                title: l10n.settingsCache,
                value: CacheService.formatBytes(_cacheBytes),
                showDivider: true,
                onTap: _cacheBytes > 0 ? _clearCache : null,
                showChevron: _cacheBytes > 0,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.storage,
                title: l10n.settingsCacheSizeLimit,
                value: l10n.settingsCacheSizeLimitValue(settings.cacheSizeLimitMb),
                showDivider: true,
                onTap: _pickCacheLimit,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.storage,
                title: l10n.settingsAutoClearOnClose,
                subtitle: l10n.settingsAutoClearOnCloseSubtitle,
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
            title: l10n.settingsSectionAbout,
            children: [
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.info,
                title: l10n.settingsVersion,
                value: _appVersion.isEmpty ? '...' : _appVersion,
                showChevron: false,
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.privacy,
                title: l10n.settingsPrivacyPolicy,
                showDivider: true,
                onTap: () => launchUrl(
                  Uri.parse(_privacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.license,
                title: l10n.settingsOpenSourceLicenses,
                showDivider: true,
                onTap: () => showLicensePage(context: context),
              ),
              OneUiSettingsTile(
                icon: OneUiSettingsIcon.share,
                title: l10n.settingsShareApp,
                showDivider: true,
                onTap: () => Share.share(l10n.settingsShareAppMessage),
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
    final l10n = context.l10n;
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
                      l10n.debugBuildTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: OneUiSpacing.xs),
                    Text(
                      l10n.debugBuildMessage,
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
    final l10n = context.l10n;
    return Semantics(
      button: true,
      selected: selected,
      label: accentPresetLabel(l10n, preset.color),
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
