import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/app/theme.dart';
import 'package:social_gallery/core/animation/app_motion.dart';

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
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Social Gallery',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final motion = AppMotion.fromSettings(
          settings,
          systemAnimationsDisabled: MediaQuery.disableAnimationsOf(context),
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: settings.fontSizeFactor,
            disableAnimations:
                !motion.enabled || MediaQuery.disableAnimationsOf(context),
          ),
          child: child!,
        );
      },
    );
  }
}
