import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/gallery/desktop_gallery_root_picker.dart';
import 'package:social_gallery/core/permissions/media_permission_service.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/core/theme/accent_presets.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/follow_status.dart';
import 'package:social_gallery/features/onboarding/onboarding_accent_swatch.dart';
import 'package:social_gallery/features/onboarding/onboarding_shell.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

const _pageCount = 6;

class OnboardingCarousel extends ConsumerStatefulWidget {
  const OnboardingCarousel({super.key});

  @override
  ConsumerState<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends ConsumerState<OnboardingCarousel> {
  final _pageController = PageController();
  int _pageIndex = 0;
  bool _syncStarted = false;

  MediaPermissionState _permissionState = MediaPermissionState.checking;
  bool _showStoragePrompt = false;
  bool _showDesktopRootPrompt = false;
  String? _permissionError;

  @override
  void initState() {
    super.initState();
    unawaited(_checkPermissions());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _permissionState = MediaPermissionState.checking;
      _permissionError = null;
    });

    final permissionService = ref.read(mediaPermissionServiceProvider);
    var permission = await permissionService.check();

    if (permission == MediaPermissionState.denied) {
      permission = await permissionService.request();
    }

    if (!mounted) return;

    if (permission == MediaPermissionState.denied) {
      setState(() => _permissionState = MediaPermissionState.denied);
      return;
    }

    setState(() => _permissionState = permission);

    if (Platform.isAndroid) {
      final storage = ref.read(storageAccessServiceProvider);
      if (!await storage.hasAllFilesAccess()) {
        setState(() => _showStoragePrompt = true);
        return;
      }
    }

    if (usesFilesystemGallery) {
      final rootPath = ref.read(preferencesRepositoryProvider).desktopGalleryRootPath;
      if (rootPath == null || rootPath.isEmpty) {
        setState(() => _showDesktopRootPrompt = true);
        return;
      }
    }

    await _startBackgroundSync();
  }

  Future<void> _startBackgroundSync() async {
    if (_syncStarted) return;
    _syncStarted = true;
    final sync = ref.read(gallerySyncProvider);
    if (!sync.isRunning) {
      unawaited(ref.read(gallerySyncProvider.notifier).run());
    }
  }

  Future<void> _requestPermission() async {
    final permission = await ref.read(mediaPermissionServiceProvider).request();
    if (permission == MediaPermissionState.denied) {
      setState(() => _permissionState = MediaPermissionState.denied);
      return;
    }
    await _checkPermissions();
  }

  Future<void> _requestAllFilesAccess() async {
    await ref.read(storageAccessServiceProvider).requestAllFilesAccess();
    setState(() => _showStoragePrompt = false);
    await _checkPermissions();
  }

  Future<void> _pickDesktopGalleryRoot() async {
    try {
      final path = await pickDesktopGalleryRootFolder();
      if (path != null && path.isNotEmpty) {
        final saved = await saveDesktopGalleryRootPath(
          ref.read(preferencesRepositoryProvider),
          path,
        );
        if (!saved) {
          setState(() => _permissionError = 'Could not use that folder');
          return;
        }
        setState(() => _showDesktopRootPrompt = false);
        await _checkPermissions();
      }
    } catch (e) {
      setState(() => _permissionError = 'Failed to select folder: $e');
    }
  }

  void _goToPage(int index) {
    final clamped = index.clamp(0, _pageCount - 1);
    setState(() => _pageIndex = clamped);
    unawaited(
      _pageController.animateToPage(
        clamped,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _nextPage() {
    if (_pageIndex >= _pageCount - 1) {
      unawaited(_completeOnboarding());
      return;
    }
    _goToPage(_pageIndex + 1);
  }

  void _previousPage() {
    if (_pageIndex <= 0) return;
    _goToPage(_pageIndex - 1);
  }

  Future<void> _completeOnboarding() async {
    await ref.read(preferencesRepositoryProvider).setInitialSetupComplete();
    if (!mounted) return;
    context.go('/home');
  }

  bool get _permissionsReady {
    if (_permissionState == MediaPermissionState.denied ||
        _permissionState == MediaPermissionState.checking) {
      return false;
    }
    if (_showStoragePrompt || _showDesktopRootPrompt) return false;
    return true;
  }

  bool get _canAdvanceFromPermissions => _permissionsReady;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) => setState(() => _pageIndex = index),
      children: [
        _WelcomePage(
          onNext: _nextPage,
          onSkip: () => _goToPage(1),
        ),
        _PermissionsPage(
          permissionState: _permissionState,
          showStoragePrompt: _showStoragePrompt,
          showDesktopRootPrompt: _showDesktopRootPrompt,
          error: _permissionError,
          canContinue: _canAdvanceFromPermissions,
          onRequestPermission: _requestPermission,
          onRequestAllFilesAccess: _requestAllFilesAccess,
          onSkipStorage: () async {
            setState(() => _showStoragePrompt = false);
            await _startBackgroundSync();
          },
          onPickDesktopRoot: _pickDesktopGalleryRoot,
          onBack: _previousPage,
          onNext: _nextPage,
        ),
        _ThemePage(
          onBack: _previousPage,
          onNext: _nextPage,
          onSkip: _nextPage,
        ),
        _AppearancePage(
          onBack: _previousPage,
          onNext: _nextPage,
          onSkip: _nextPage,
        ),
        _ViewModePage(
          onBack: _previousPage,
          onNext: _nextPage,
          onSkip: _nextPage,
        ),
        _FoldersPage(
          onBack: _previousPage,
          onComplete: _completeOnboarding,
        ),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext, required this.onSkip});

  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingShell(
      pageIndex: 0,
      pageCount: _pageCount,
      showBack: false,
      showSkip: true,
      onSkip: onSkip,
      onNext: onNext,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.pageHorizontal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_rounded,
              size: 88,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: OneUiSpacing.xl),
            Text(
              'Welcome to Social Gallery',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OneUiSpacing.md),
            Text(
              'Your photos stay on your device. Set up a few preferences '
              'and we will index your library in the background.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({
    required this.permissionState,
    required this.showStoragePrompt,
    required this.showDesktopRootPrompt,
    required this.error,
    required this.canContinue,
    required this.onRequestPermission,
    required this.onRequestAllFilesAccess,
    required this.onSkipStorage,
    required this.onPickDesktopRoot,
    required this.onBack,
    required this.onNext,
  });

  final MediaPermissionState permissionState;
  final bool showStoragePrompt;
  final bool showDesktopRootPrompt;
  final String? error;
  final bool canContinue;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onRequestAllFilesAccess;
  final Future<void> Function() onSkipStorage;
  final Future<void> Function() onPickDesktopRoot;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (showDesktopRootPrompt) {
      body = _PermissionCard(
        icon: Icons.folder_open_outlined,
        title: 'Select gallery folder',
        message:
            'Choose a folder on your computer to scan for photos and videos.',
        error: error,
        actions: [
          FilledButton.icon(
            onPressed: onPickDesktopRoot,
            icon: const Icon(Icons.folder),
            label: const Text('Choose folder'),
          ),
        ],
      );
    } else if (showStoragePrompt) {
      body = _PermissionCard(
        icon: Icons.folder_shared_outlined,
        title: 'All files access (optional)',
        message:
            'On Android 11+, grant "All files access" to move or delete items '
            'between albums. You can skip and grant it later.',
        actions: [
          FilledButton(
            onPressed: onRequestAllFilesAccess,
            child: const Text('Grant access'),
          ),
          TextButton(
            onPressed: onSkipStorage,
            child: const Text('Continue without'),
          ),
        ],
      );
    } else if (permissionState == MediaPermissionState.denied) {
      body = _PermissionCard(
        icon: Icons.photo_library_outlined,
        title: 'Photos access required',
        message:
            'Social Gallery needs access to your photos and videos to build your library.',
        error: error,
        actions: [
          FilledButton(
            onPressed: onRequestPermission,
            child: const Text('Grant permission'),
          ),
        ],
      );
    } else if (permissionState == MediaPermissionState.checking) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = _PermissionCard(
        icon: Icons.check_circle_outline,
        title: 'Access granted',
        message: permissionState == MediaPermissionState.limited
            ? 'Limited photo access is enabled. Your library is indexing in the background.'
            : 'Your library is indexing in the background while you finish setup.',
        actions: const [],
      );
    }

    return OnboardingShell(
      pageIndex: 1,
      pageCount: _pageCount,
      onBack: onBack,
      onNext: onNext,
      nextEnabled: canContinue,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OneUiPageHeader(
              title: 'Permissions',
              subtitle: 'Allow access so we can scan your albums.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OneUiSpacing.pageHorizontal,
              ),
              child: body,
            ),
            if (canContinue) ...[
              const SizedBox(height: OneUiSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: OneUiSpacing.pageHorizontal,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gallery sync running in background',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.message,
    this.error,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? error;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(OneUiSpacing.lg),
        child: Column(
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: OneUiSpacing.md),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: OneUiSpacing.sm),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (error != null) ...[
              const SizedBox(height: OneUiSpacing.sm),
              Text(
                error!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: OneUiSpacing.lg),
              ...actions.map(
                (action) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: action,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemePage extends ConsumerWidget {
  const _ThemePage({
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static const _options = [
    (AppThemeVariant.system, 'System default', Icons.brightness_auto_outlined),
    (AppThemeVariant.light, 'Light', Icons.light_mode_outlined),
    (AppThemeVariant.solar, 'Solar', Icons.wb_sunny_outlined),
    (AppThemeVariant.dark, 'Dark', Icons.dark_mode_outlined),
    (AppThemeVariant.darkOled, 'Dark OLED', Icons.contrast_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider.select((s) => s.appTheme));
    final theme = Theme.of(context);

    return OnboardingShell(
      pageIndex: 2,
      pageCount: _pageCount,
      showSkip: true,
      onSkip: onSkip,
      onBack: onBack,
      onNext: onNext,
      child: ListView(
        padding: const EdgeInsets.only(bottom: OneUiSpacing.lg),
        children: [
          const OneUiPageHeader(
            title: 'Choose a theme',
            subtitle: 'Pick how Social Gallery looks. You can change this later.',
          ),
          ..._options.map((option) {
            final selected = current == option.$1;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: OneUiSpacing.pageHorizontal,
                vertical: 4,
              ),
              child: Material(
                color: selected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(OneUiRadii.card),
                child: ListTile(
                  leading: Icon(option.$3),
                  title: Text(option.$2),
                  trailing: selected
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    AppHaptics.medium();
                    ref.read(settingsProvider.notifier).setAppTheme(option.$1);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AppearancePage extends ConsumerWidget {
  const _AppearancePage({
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  String _fontLabel(double factor) {
    if (factor < 0.9) return 'Small';
    if (factor < 1.1) return 'Normal';
    if (factor < 1.3) return 'Large';
    return 'Extra large';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return OnboardingShell(
      pageIndex: 3,
      pageCount: _pageCount,
      showSkip: true,
      onSkip: onSkip,
      onBack: onBack,
      onNext: onNext,
      child: ListView(
        padding: const EdgeInsets.only(bottom: OneUiSpacing.lg),
        children: [
          const OneUiPageHeader(
            title: 'Accent and text',
            subtitle: 'Fine-tune colors and readability.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.pageHorizontal),
            child: Text('Accent color', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: OneUiSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.pageHorizontal),
            child: Wrap(
              spacing: OneUiSpacing.md,
              runSpacing: OneUiSpacing.md,
              children: [
                for (final preset in AccentPresets.all)
                  OnboardingAccentSwatch(
                    preset: preset,
                    selected: preset.color.toARGB32() == settings.accentColor.toARGB32(),
                    onTap: () {
                      AppHaptics.medium();
                      ref.read(settingsProvider.notifier).setAccentColor(preset.color);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: OneUiSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.pageHorizontal),
            child: Text('Font size', style: theme.textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.pageHorizontal),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.format_size_outlined, size: 18),
                    Expanded(
                      child: Slider(
                        value: settings.fontSizeFactor,
                        min: 0.8,
                        max: 1.4,
                        divisions: 3,
                        label: _fontLabel(settings.fontSizeFactor),
                        onChanged: (value) {
                          AppHaptics.selection();
                          ref.read(settingsProvider.notifier).setFontSizeFactor(value);
                        },
                      ),
                    ),
                    const Icon(Icons.format_size_outlined, size: 26),
                  ],
                ),
                Text(
                  _fontLabel(settings.fontSizeFactor),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModePage extends ConsumerWidget {
  const _ViewModePage({
    required this.onBack,
    required this.onNext,
    required this.onSkip,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryViewMode = ref.watch(
      settingsProvider.select((s) => s.galleryViewMode),
    );
    final theme = Theme.of(context);

    return OnboardingShell(
      pageIndex: 4,
      pageCount: _pageCount,
      showSkip: true,
      onSkip: onSkip,
      onBack: onBack,
      onNext: onNext,
      child: ListView(
        padding: const EdgeInsets.only(bottom: OneUiSpacing.lg),
        children: [
          const OneUiPageHeader(
            title: 'Gallery or social?',
            subtitle: 'Choose your default browsing style.',
          ),
          _ViewModeCard(
            selected: !galleryViewMode,
            icon: Icons.home_outlined,
            title: 'Social style',
            description:
                'Home feed with stories and posts, plus an Explore tab for discovery.',
            onTap: () {
              AppHaptics.medium();
              ref.read(settingsProvider.notifier).setGalleryViewMode(false);
            },
          ),
          _ViewModeCard(
            selected: galleryViewMode,
            icon: Icons.grid_view_rounded,
            title: 'Gallery style',
            description:
                'Pinch-zoom gallery grid on Home with albums on Explore.',
            onTap: () {
              AppHaptics.medium();
              ref.read(settingsProvider.notifier).setGalleryViewMode(true);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(OneUiSpacing.pageHorizontal),
            child: Text(
              'You can switch modes anytime in Settings.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeCard extends StatelessWidget {
  const _ViewModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OneUiSpacing.pageHorizontal,
        vertical: 6,
      ),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(OneUiRadii.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(OneUiRadii.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(OneUiSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 32, color: theme.colorScheme.primary),
                const SizedBox(width: OneUiSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(description, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FoldersPage extends ConsumerWidget {
  const _FoldersPage({
    required this.onBack,
    required this.onComplete,
  });

  final VoidCallback onBack;
  final Future<void> Function() onComplete;

  Future<void> _setVisibility(
    WidgetRef ref,
    FolderInfo folder,
    FollowStatus status, {
    bool locked = false,
  }) async {
    AppHaptics.medium();
    await ref.read(folderRepositoryProvider).updateFollowStatus(
          folder.path,
          status,
          isBiometricLocked: locked,
        );
    if (locked) {
      ref.read(folderUnlockStoreProvider).lock(folder.path);
    }
    ref.invalidate(allFoldersProvider);
    refreshFeedProviders(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(allFoldersProvider);
    final theme = Theme.of(context);

    return OnboardingShell(
      pageIndex: 5,
      pageCount: _pageCount,
      onBack: onBack,
      onNext: onComplete,
      nextLabel: 'Get started',
      child: foldersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load folders: $e')),
        data: (folders) {
          if (folders.isEmpty) {
            return ListView(
              children: [
                const OneUiPageHeader(
                  title: 'Your folders',
                  subtitle:
                      'Indexing is still running. You can adjust folders later in Settings.',
                ),
                Padding(
                  padding: const EdgeInsets.all(OneUiSpacing.pageHorizontal),
                  child: Text(
                    'No folders found yet. Tap Get started to enter the app '
                    'while sync continues.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: OneUiSpacing.lg),
            itemCount: folders.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const OneUiPageHeader(
                  title: 'Your folders',
                  subtitle:
                      'Choose what appears on Home Feed, as account-only, or hidden.',
                );
              }
              final folder = folders[index - 1];
              return _OnboardingFolderTile(
                folder: folder,
                onHomeFeed: () => _setVisibility(
                  ref,
                  folder,
                  FollowStatus.homeFeed,
                ),
                onAccount: () => _setVisibility(
                  ref,
                  folder,
                  FollowStatus.accountOnly,
                ),
                onLocked: () => _setVisibility(
                  ref,
                  folder,
                  FollowStatus.accountOnly,
                  locked: true,
                ),
                onHidden: () => _setVisibility(
                  ref,
                  folder,
                  FollowStatus.unfollowed,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OnboardingFolderTile extends StatelessWidget {
  const _OnboardingFolderTile({
    required this.folder,
    required this.onHomeFeed,
    required this.onAccount,
    required this.onLocked,
    required this.onHidden,
  });

  final FolderInfo folder;
  final VoidCallback onHomeFeed;
  final VoidCallback onAccount;
  final VoidCallback onLocked;
  final VoidCallback onHidden;

  @override
  Widget build(BuildContext context) {
    final locked = folder.isLockedAccount;
    final statusLabel = switch (folder.followStatus) {
      FollowStatus.homeFeed => locked ? 'Locked' : 'Home Feed',
      FollowStatus.accountOnly => locked ? 'Account (locked)' : 'Account',
      FollowStatus.unfollowed => 'Hidden',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OneUiSpacing.pageHorizontal,
        vertical: 4,
      ),
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: FolderAvatar(
                  name: folder.name,
                  coverUri: locked ? null : folder.displayCoverUri,
                  locked: locked,
                ),
                title: Text(folder.name),
                subtitle: Text('${folder.mediaCount} items'),
                trailing: Chip(label: Text(statusLabel)),
              ),
              const Divider(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _VisibilityChip(
                    label: 'Home',
                    selected: folder.followStatus == FollowStatus.homeFeed && !locked,
                    onTap: onHomeFeed,
                  ),
                  _VisibilityChip(
                    label: 'Account',
                    selected:
                        folder.followStatus == FollowStatus.accountOnly && !locked,
                    onTap: onAccount,
                  ),
                  _VisibilityChip(
                    label: 'Lock',
                    selected: locked,
                    onTap: onLocked,
                  ),
                  _VisibilityChip(
                    label: 'Hide',
                    selected: folder.followStatus == FollowStatus.unfollowed,
                    onTap: onHidden,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }
}
