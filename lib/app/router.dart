import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/features/discover/duplicate_review_screen.dart';
import 'package:social_gallery/features/discover/duplicates_screen.dart';
import 'package:social_gallery/features/explore/explore_screen.dart';
import 'package:social_gallery/features/favorites/favorites_screen.dart';
import 'package:social_gallery/features/folder_management/folder_management_screen.dart';
import 'package:social_gallery/features/folder_profile/folder_profile_screen.dart';
import 'package:social_gallery/features/home/home_screen.dart';
import 'package:social_gallery/features/discover/discover_screen.dart';
import 'package:social_gallery/features/media_viewer/media_viewer_screen.dart';
import 'package:social_gallery/features/profile/profile_screen.dart';
import 'package:social_gallery/features/shell/main_shell.dart';
import 'package:social_gallery/features/startup/startup_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/startup',
    routes: [
      GoRoute(
        path: '/startup',
        builder: (context, state) => const StartupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/folder_management',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FolderManagementScreen(),
      ),
      GoRoute(
        path: '/folder_profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';
          return FolderProfileScreen(folderPath: path);
        },
      ),
      GoRoute(
        path: '/duplicates',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DuplicatesScreen(),
      ),
      GoRoute(
        path: '/duplicate_review',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final key = state.uri.queryParameters['key'] ?? '';
          return DuplicateReviewScreen(groupKey: key);
        },
      ),
      GoRoute(
        path: '/media_viewer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final assetId = state.uri.queryParameters['assetId'] ?? '';
          final mediaId = int.tryParse(
                state.uri.queryParameters['mediaId'] ?? '',
              ) ??
              0;
          final favorite = state.uri.queryParameters['favorite'] == '1';
          return MediaViewerScreen(
            assetId: assetId,
            mediaId: mediaId,
            initialFavorite: favorite,
          );
        },
      ),
    ],
  );
});

String folderProfileLocation(String path) =>
    '/folder_profile?path=${Uri.encodeComponent(path)}';

String duplicateReviewLocation(String groupKey) =>
    '/duplicate_review?key=${Uri.encodeComponent(groupKey)}';

String mediaViewerLocation(
  String assetId, {
  required int mediaId,
  bool favorite = false,
}) =>
    '/media_viewer?assetId=${Uri.encodeComponent(assetId)}&mediaId=$mediaId&favorite=${favorite ? 1 : 0}';
