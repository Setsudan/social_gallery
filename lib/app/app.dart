import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/app/theme.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/sync/gallery_sync_controller.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';

/// Root widget: theme, lifecycle sync, and feed refresh coordination.
class SocialGalleryApp extends ConsumerStatefulWidget {
  const SocialGalleryApp({super.key});

  @override
  ConsumerState<SocialGalleryApp> createState() => _SocialGalleryAppState();
}

class _SocialGalleryAppState extends ConsumerState<SocialGalleryApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(duplicateScanNotificationServiceProvider).setAppInForeground(
          state == AppLifecycleState.resumed,
        );

    if (state == AppLifecycleState.resumed) {
      refreshFeedProviders(ref);
      unawaited(ref.read(gallerySyncProvider.notifier).run());
    }

    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      final settings = ref.read(settingsProvider);
      if (settings.autoClearCacheOnClose) {
        ref.read(cacheServiceProvider).clearCache();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(feedRefreshCoordinatorProvider);

    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    final resolvedTheme = resolveAppThemeVariant(
      settings.appTheme,
      platformBrightness,
    );
    final theme = AppTheme.build(
      variant: resolvedTheme,
      accent: settings.accentColor,
    );

    return AnimatedTheme(
      data: theme,
      duration: const Duration(milliseconds: 200),
      child: MaterialApp.router(
        title: 'Social Gallery (beta)',
        theme: theme,
        routerConfig: router,
        builder: (context, child) {
          final motion = AppMotion.fromSettings(
            settings,
            systemAnimationsDisabled: MediaQuery.disableAnimationsOf(context),
          );
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.fontSizeFactor),
              disableAnimations:
                  !motion.enabled || MediaQuery.disableAnimationsOf(context),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
