import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/app_locale_preference.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/l10n/app_localizations.dart';
import 'package:social_gallery/core/backup/backup_deep_link.dart';
import 'package:social_gallery/core/backup/desktop_backup_window_guard.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/notifications/desktop_backup_notification_service.dart';
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
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handleDeepLink(initial);
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  /// Maps `socialgallery://…` hosts to real go_router locations.
  String? _locationForWidgetDeepLink(Uri uri) {
    switch (uri.host) {
      case 'widgets':
        final widgetId =
            int.tryParse(uri.queryParameters['widgetId'] ?? '') ?? 0;
        // Path may be /folder-config when URI is socialgallery://widgets/folder-config
        if (uri.path.contains('folder-config') ||
            uri.pathSegments.contains('folder-config')) {
          return '/widgets/folder-config?widgetId=$widgetId';
        }
        return '/widgets/folder-config?widgetId=$widgetId';
      case 'organize':
        return '/organize';
      case 'favorites':
        return '/discover/likes-review';
      case 'gallery':
        return '/explore';
      case 'folder':
        final path = uri.queryParameters['path'];
        if (path != null && path.isNotEmpty) {
          return folderProfileLocation(path);
        }
        return '/home';
      case 'home':
        return '/home';
      default:
        return null;
    }
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'socialgallery') return;

    if (uri.host == 'pair') {
      _handleBackupDeepLink(uri);
      return;
    }

    final location = _locationForWidgetDeepLink(uri);
    if (location == null) return;

    ref.read(pendingDeepLinkLocationProvider.notifier).state = location;
    _tryConsumePendingDeepLink();
  }

  void _handleBackupDeepLink(Uri uri) {
    final params = BackupDeepLink.parse(uri);
    if (params == null) return;
    ref.read(pendingBackupPairProvider.notifier).state = params;
  }

  void _tryConsumePendingDeepLink() {
    final location = ref.read(pendingDeepLinkLocationProvider);
    if (location == null) return;

    final router = ref.read(routerProvider);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == '/startup' || currentPath.isEmpty) {
      // Startup / onboarding still owns navigation; keep queued.
      return;
    }

    ref.read(pendingDeepLinkLocationProvider.notifier).state = null;

    final isShellTab =
        location == '/home' || location == '/explore' || location == '/discover';
    if (isShellTab) {
      router.go(location);
    } else {
      // Ensure a shell tab is under the modal stack.
      if (currentPath == '/startup') {
        router.go('/home');
      }
      router.push(location);
    }
  }

  Future<void> _consumePendingBackupPair() async {
    if (usesFilesystemGallery) return;
    final params = ref.read(pendingBackupPairProvider);
    if (params == null) return;
    ref.read(pendingBackupPairProvider.notifier).state = null;

    final ok = await ref.read(desktopBackupProvider.notifier).pairWithDesktop(
      host: params.address,
      port: params.port,
      pin: params.pin,
      mobileDeviceName: Platform.localHostname,
    );
    if (ok) {
      await ref.read(desktopBackupProvider.notifier).setBackupEnabled(true);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(duplicateScanNotificationServiceProvider).setAppInForeground(
          state == AppLifecycleState.resumed,
        );
    ref.read(desktopBackupNotificationServiceProvider).setAppInForeground(
          state == AppLifecycleState.resumed,
        );

    if (state == AppLifecycleState.resumed) {
      refreshFeedProviders(ref);
      unawaited(ref.read(gallerySyncProvider.notifier).run());
      // Cold-start deep links may arrive before shell is ready.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryConsumePendingDeepLink();
      });
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

    ref.listen<GallerySyncState>(gallerySyncProvider, (previous, next) {
      if (previous?.isRunning == true &&
          !next.isRunning &&
          next.phase == GallerySyncPhase.done) {
        unawaited(ref.read(desktopBackupProvider.notifier).checkAndMaybeRun());
      }
    });

    ref.listen<BackupPairingParams?>(pendingBackupPairProvider, (previous, next) {
      if (next != null) {
        unawaited(_consumePendingBackupPair());
      }
    });

    ref.listen<String?>(pendingDeepLinkLocationProvider, (previous, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tryConsumePendingDeepLink();
        });
      }
    });

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

    return DesktopBackupWindowGuard(
      child: AnimatedTheme(
        data: theme,
        duration: const Duration(milliseconds: 200),
        child: MaterialApp.router(
          onGenerateTitle: (context) => context.l10n.appTitle,
          theme: theme,
          routerConfig: router,
          locale: settings.localePreference.toLocale(),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalePreference.supportedLocales,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return AppLocalePreference.resolveLocale(
              preference: settings.localePreference,
              deviceLocale: deviceLocale,
            );
          },
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
      ),
    );
  }
}
