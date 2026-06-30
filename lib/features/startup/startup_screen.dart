import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/permissions/media_permission_service.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/features/onboarding/onboarding_carousel.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  bool _checking = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    if (!prefs.hasCompletedInitialSetup) {
      if (mounted) {
        setState(() {
          _checking = false;
          _showOnboarding = true;
        });
      }
      return;
    }

    await _bootstrapReturningUser();
  }

  Future<void> _bootstrapReturningUser() async {
    final permissionService = ref.read(mediaPermissionServiceProvider);
    var permission = await permissionService.check();

    if (permission == MediaPermissionState.denied) {
      permission = await permissionService.request();
    }

    if (!mounted) return;

    if (permission == MediaPermissionState.denied) {
      setState(() {
        _checking = false;
        _showOnboarding = true;
      });
      return;
    }

    if (usesFilesystemGallery) {
      final rootPath = ref.read(preferencesRepositoryProvider).desktopGalleryRootPath;
      if (rootPath == null || rootPath.isEmpty) {
        setState(() {
          _checking = false;
          _showOnboarding = true;
        });
        return;
      }
    }

    await _enterApp();
  }

  Future<void> _enterApp() async {
    if (!mounted) return;
    final syncNotifier = ref.read(gallerySyncProvider.notifier);
    final sync = ref.read(gallerySyncProvider);
    if (!sync.isRunning) {
      unawaited(syncNotifier.run());
    }
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showOnboarding) {
      return const OnboardingCarousel();
    }

    return const SizedBox.shrink();
  }
}
