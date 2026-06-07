import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/core/cache/cache_service.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_group_card.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl = 'https://example.com/privacy';

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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            AppHaptics.light();
            context.pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: OneUiSpacing.xl),
        children: [
          const OneUiPageHeader(title: 'Settings'),
          OneUiGroupCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            child: DropdownButtonFormField<ThemeMode>(
              initialValue: settings.themeMode,
              decoration: const InputDecoration(labelText: 'Theme'),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Default'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light Mode'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark Mode'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  AppHaptics.medium();
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiGroupCard(
            title: 'Font Size',
            icon: Icons.text_fields_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Scale the app text size to fit your preferences.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: OneUiSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.format_size_outlined, size: 16),
                    Expanded(
                      child: Slider(
                        value: settings.fontSizeFactor,
                        min: 0.8,
                        max: 1.4,
                        divisions: 3,
                        label: _fontLabel(settings.fontSizeFactor),
                        onChanged: (value) {
                          AppHaptics.selection();
                          ref
                              .read(settingsProvider.notifier)
                              .setFontSizeFactor(value);
                        },
                      ),
                    ),
                    const Icon(Icons.format_size_outlined, size: 28),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiGroupCard(
            title: 'Animation Speed',
            icon: Icons.motion_photos_auto_outlined,
            child: DropdownButtonFormField<double>(
              initialValue: settings.animationSpeed,
              decoration: const InputDecoration(labelText: 'Speed Factor'),
              items: const [
                DropdownMenuItem(
                  value: 0.001,
                  child: Text('Disabled (Instant)'),
                ),
                DropdownMenuItem(
                  value: 0.5,
                  child: Text('Fast (0.5x duration)'),
                ),
                DropdownMenuItem(value: 1.0, child: Text('Normal (1.0x)')),
                DropdownMenuItem(value: 2.0, child: Text('Slow Motion (2.0x)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  AppHaptics.medium();
                  ref.read(settingsProvider.notifier).setAnimationSpeed(value);
                }
              },
            ),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiGroupCard(
            title: 'Gallery',
            icon: Icons.photo_library_outlined,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Gallery view mode'),
              subtitle: const Text(
                'Replace Home and Explore with a pinch-zoom gallery tab',
              ),
              value: settings.galleryViewMode,
              onChanged: (value) {
                AppHaptics.medium();
                ref.read(settingsProvider.notifier).setGalleryViewMode(value);
              },
            ),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiGroupCard(
            title: 'Content',
            icon: Icons.folder_outlined,
            child: Column(
              children: [
                OneUiListRow(
                  title: 'Manage Content',
                  subtitle: 'Folders, home feed, and visibility',
                  onTap: () {
                    AppHaptics.light();
                    context.push('/folder_management');
                  },
                ),
                OneUiListRow(
                  title: 'Travel Mode',
                  subtitle: 'Trips and date-range organization',
                  showDivider: true,
                  onTap: () {
                    AppHaptics.light();
                    context.push('/travel_mode');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          _OrganizeSettingsCard(),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiGroupCard(
            title: 'Trash Retention',
            icon: Icons.delete_sweep_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Items in trash are permanently removed after this period.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: OneUiSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: settings.trashRetentionDays.toDouble(),
                        min: 1,
                        max: 90,
                        divisions: 89,
                        label: '${settings.trashRetentionDays} Days',
                        onChanged: (value) {
                          AppHaptics.selection();
                          ref
                              .read(settingsProvider.notifier)
                              .setTrashRetentionDays(value.toInt());
                        },
                      ),
                    ),
                    Text(
                      '${settings.trashRetentionDays} Days',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                OneUiListRow(
                  title: 'Manage Deleted Items',
                  subtitle: 'View, restore, or empty trash',
                  showDivider: true,
                  onTap: () {
                    AppHaptics.light();
                    context.push('/trash');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiGroupCard(
            title: 'Cache',
            icon: Icons.storage_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Current size'),
                  subtitle: Text(CacheService.formatBytes(_cacheBytes)),
                ),
                FilledButton.tonal(
                  onPressed: _cacheBytes > 0 ? _clearCache : null,
                  child: const Text('Clear cache'),
                ),
                const SizedBox(height: OneUiSpacing.md),
                Text('Size limit: ${settings.cacheSizeLimitMb} MB'),
                Slider(
                  value: settings.cacheSizeLimitMb.toDouble(),
                  min: 100,
                  max: 2000,
                  divisions: 19,
                  label: '${settings.cacheSizeLimitMb} MB',
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setCacheSizeLimitMb(value.round());
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-clear on close'),
                  subtitle: const Text('Clear cache when the app is closed'),
                  value: settings.autoClearCacheOnClose,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setAutoClearCacheOnClose(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: OneUiSpacing.sectionGap),
          OneUiGroupCard(
            title: 'About',
            icon: Icons.info_outline,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Version'),
                  subtitle: Text(_appVersion.isEmpty ? '...' : _appVersion),
                ),
                OneUiListRow(
                  title: 'Privacy policy',
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  showDivider: true,
                  onTap: () => launchUrl(
                    Uri.parse(_privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                OneUiListRow(
                  title: 'Open-source licenses',
                  showDivider: true,
                  onTap: () => showLicensePage(context: context),
                ),
                OneUiListRow(
                  title: 'Share app',
                  trailing: const Icon(Icons.share_outlined, size: 20),
                  showDivider: true,
                  onTap: () => Share.share(
                    'Check out Social Gallery - a local-first photo gallery.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fontLabel(double factor) {
    if (factor < 0.9) return 'Small';
    if (factor < 1.1) return 'Normal';
    if (factor < 1.3) return 'Large';
    return 'Extra Large';
  }
}

class _OrganizeSettingsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.watch(organizeRepositoryProvider);
    final batchSize = repo.batchSize;
    final queueOrder = repo.queueOrder;

    return OneUiGroupCard(
      title: 'Organize',
      icon: Icons.swipe,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Configure the swipe organizer on the Discover tab.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: OneUiSpacing.md),
          Text('Batch size: $batchSize'),
          Slider(
            value: batchSize.toDouble(),
            min: 10,
            max: 30,
            divisions: 20,
            label: '$batchSize',
            onChanged: (value) => repo.setBatchSize(value.round()),
          ),
          const SizedBox(height: OneUiSpacing.sm),
          SegmentedButton<OrganizeQueueOrder>(
            segments: const [
              ButtonSegment(
                value: OrganizeQueueOrder.random,
                label: Text('Random'),
              ),
              ButtonSegment(
                value: OrganizeQueueOrder.chronological,
                label: Text('Time'),
              ),
            ],
            selected: {queueOrder},
            onSelectionChanged: (set) => repo.setQueueOrder(set.first),
          ),
          const SizedBox(height: OneUiSpacing.md),
          FilledButton.tonal(
            onPressed: () async {
              await repo.clearProcessed();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Released kept photos')),
                );
              }
            },
            child: const Text('Release kept photos'),
          ),
        ],
      ),
    );
  }
}
