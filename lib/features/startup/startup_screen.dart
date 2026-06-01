import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/permissions/media_permission_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:social_gallery/core/workers/trash_cleanup_worker.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  MediaPermissionState _state = MediaPermissionState.checking;

  bool _showStoragePrompt = false;
  bool _showWindowsRootPrompt = false;

  String? _error;

  bool _syncing = false;

  @override
  void initState() {
    super.initState();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _state = MediaPermissionState.checking;
      _showStoragePrompt = false;
      _showWindowsRootPrompt = false;
      _error = null;
    });

    final permissionService = ref.read(mediaPermissionServiceProvider);

    var permission = await permissionService.check();

    if (permission == MediaPermissionState.denied) {
      setState(() => _state = MediaPermissionState.denied);

      return;
    }

    if (permission == MediaPermissionState.checking) {
      permission = await permissionService.request();
    }

    if (permission == MediaPermissionState.denied) {
      setState(() => _state = MediaPermissionState.denied);

      return;
    }

    if (Platform.isAndroid) {
      final storage = ref.read(storageAccessServiceProvider);

      if (!await storage.hasAllFilesAccess()) {
        setState(() => _showStoragePrompt = true);

        return;
      }
    }

    final preferences = ref.read(preferencesRepositoryProvider);

    if (Platform.isWindows) {
      final rootPath = preferences.windowsGalleryRootPath;
      if (rootPath == null || rootPath.isEmpty) {
        setState(() {
          _showWindowsRootPrompt = true;
          _showStoragePrompt = false;
        });
        return;
      }
    }

    if (preferences.hasCompletedInitialSetup) {
      _backgroundSync();

      if (mounted) context.go('/home');

      return;
    }

    await _syncAndEnter();
  }

  Future<void> _pickWindowsRootFolder() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Root Gallery Folder',
      );
      if (path != null && path.isNotEmpty) {
        final prefs = ref.read(preferencesRepositoryProvider);
        await prefs.setWindowsGalleryRootPath(path);
        setState(() => _showWindowsRootPrompt = false);
        await _bootstrap();
      }
    } catch (e) {
      setState(() => _error = 'Failed to select folder: $e');
    }
  }

  void _backgroundSync() {
    Future.microtask(() async {
      ref.read(syncStateProvider.notifier).state = true;
      try {
        final repo = ref.read(mediaRepositoryProvider);
        final settings = ref.read(settingsProvider);
        await repo.cleanupExpiredTrash(settings.trashRetentionDays);
        await repo.syncFromDevice();
        try {
          await registerTrashCleanupWork();
        } catch (_) {}
      } catch (e) {
        debugPrint('Background sync error: $e');
      } finally {
        ref.read(syncStateProvider.notifier).state = false;
      }
    });
  }

  Future<void> _syncAndEnter() async {
    setState(() {
      _showStoragePrompt = false;
      _syncing = true;
      _error = null;
    });

    try {
      final repo = ref.read(mediaRepositoryProvider);
      final settings = ref.read(settingsProvider);
      await repo.cleanupExpiredTrash(settings.trashRetentionDays);
      await repo.syncFromDevice();
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() {
        _error = e.toString();
        _syncing = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final permission = await ref.read(mediaPermissionServiceProvider).request();

    if (permission == MediaPermissionState.denied) {
      setState(() => _state = MediaPermissionState.denied);

      return;
    }

    await _bootstrap();
  }

  Future<void> _requestAllFilesAccess() async {
    await ref.read(storageAccessServiceProvider).requestAllFilesAccess();

    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    if (_showWindowsRootPrompt) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_open_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Select Gallery Root Directory',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a local directory on your computer to scan and display photos and videos in your gallery.',
                  textAlign: TextAlign.center,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _pickWindowsRootFolder,
                  icon: const Icon(Icons.folder),
                  label: const Text('Choose Folder'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_showStoragePrompt) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                const Icon(Icons.folder_shared_outlined, size: 56),

                const SizedBox(height: 16),

                Text(
                  'All files access (optional)',

                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 12),

                const Text(
                  'On Android 11+, grant "All files access" to move or delete '
                  'items between albums. You can skip and grant it later when '
                  'deleting duplicates.',

                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _requestAllFilesAccess,

                  child: const Text('Grant access'),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: _syncAndEnter,

                  child: const Text('Continue without'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_state == MediaPermissionState.checking || _syncing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              CircularProgressIndicator(),

              SizedBox(height: 16),

              Text('Preparing your gallery...'),
            ],
          ),
        ),
      );
    }

    if (_state == MediaPermissionState.denied) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                const Icon(Icons.photo_library_outlined, size: 56),

                const SizedBox(height: 16),

                Text(
                  'Permission Required',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Social Gallery needs access to your photos and videos to build your local library.',

                  textAlign: TextAlign.center,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),

                  Text(
                    _error!,

                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),

                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: _requestPermission,

                  child: const Text('Grant Permission'),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: _bootstrap,

                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
