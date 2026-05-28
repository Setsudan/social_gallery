import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:social_gallery/core/animation/page_transitions.dart';

import 'package:social_gallery/features/discover/duplicate_review_screen.dart';

import 'package:social_gallery/features/discover/duplicates_screen.dart';

import 'package:social_gallery/features/discover/discover_stub_screen.dart';

import 'package:social_gallery/features/explore/explore_screen.dart';

import 'package:social_gallery/features/favorites/favorites_screen.dart';

import 'package:social_gallery/features/folder_management/folder_management_screen.dart';

import 'package:social_gallery/features/folder_profile/folder_profile_screen.dart';

import 'package:social_gallery/features/home/home_screen.dart';

import 'package:social_gallery/features/discover/discover_screen.dart';

import 'package:social_gallery/features/media_viewer/media_viewer_screen.dart';

import 'package:social_gallery/features/post_detail/post_detail_screen.dart';

import 'package:social_gallery/features/profile/profile_screen.dart';

import 'package:social_gallery/features/shell/main_shell.dart';

import 'package:social_gallery/features/startup/startup_screen.dart';

import 'package:social_gallery/features/settings/settings_screen.dart';

import 'package:social_gallery/features/trash/trash_screen.dart';

import 'package:social_gallery/features/story_viewer/story_viewer_screen.dart';

import 'package:social_gallery/features/travel_mode/travel_mode_editor_screen.dart';

import 'package:social_gallery/features/travel_mode/travel_mode_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _page(
  BuildContext context,
  Ref ref,
  GoRouterState state,
  Widget child,
) {
  return appTransitionPage<void>(
    context: context,
    ref: ref,
    state: state,
    child: child,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,

    initialLocation: '/startup',

    routes: [
      GoRoute(
        path: '/startup',

        pageBuilder: (context, state) =>
            _page(context, ref, state, const StartupScreen()),
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

                pageBuilder: (context, state) =>
                    _page(context, ref, state, const HomeScreen()),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',

                pageBuilder: (context, state) =>
                    _page(context, ref, state, const ExploreScreen()),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',

                pageBuilder: (context, state) =>
                    _page(context, ref, state, const DiscoverScreen()),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',

                pageBuilder: (context, state) =>
                    _page(context, ref, state, const FavoritesScreen()),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',

                pageBuilder: (context, state) =>
                    _page(context, ref, state, const ProfileScreen()),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/folder_management',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) =>
            _page(context, ref, state, const FolderManagementScreen()),
      ),

      GoRoute(
        path: '/folder_profile',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';

          return _page(
            context,
            ref,
            state,
            FolderProfileScreen(folderPath: path),
          );
        },
      ),

      GoRoute(
        path: '/duplicates',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) =>
            _page(context, ref, state, const DuplicatesScreen()),
      ),

      GoRoute(
        path: '/duplicate_review',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) {
          final key = state.uri.queryParameters['key'] ?? '';

          return _page(
            context,
            ref,
            state,
            DuplicateReviewScreen(groupKey: key),
          );
        },
      ),

      GoRoute(
        path: '/discover/bursts',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) => _page(
          context,
          ref,
          state,
          const DiscoverStubScreen(
            title: 'Bursts',

            message:
                'Burst detection is not available yet. This screen will group rapid-fire shots.',

            icon: Icons.burst_mode,
          ),
        ),
      ),

      GoRoute(
        path: '/discover/suggestions',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) => _page(
          context,
          ref,
          state,
          const DiscoverStubScreen(
            title: 'Smart suggestions',

            message:
                'Suggestions will highlight albums and clean-up ideas based on your library.',

            icon: Icons.auto_awesome_outlined,
          ),
        ),
      ),

      GoRoute(
        path: '/discover/locations',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) => _page(
          context,
          ref,
          state,
          const DiscoverStubScreen(
            title: 'Locations',

            message:
                'Location clustering requires heavier indexing and will be added in a future update.',

            icon: Icons.place_outlined,
          ),
        ),
      ),

      GoRoute(
        path: '/post_detail',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) {
          final assetId = state.uri.queryParameters['assetId'] ?? '';

          final mediaId =
              int.tryParse(state.uri.queryParameters['mediaId'] ?? '') ?? 0;

          final favorite = state.uri.queryParameters['favorite'] == '1';

          return _page(
            context,
            ref,
            state,
            PostDetailScreen(
              assetId: assetId,

              mediaId: mediaId,

              initialFavorite: favorite,
            ),
          );
        },
      ),

      GoRoute(
        path: '/media_viewer',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) {
          final assetId = state.uri.queryParameters['assetId'] ?? '';

          final mediaId =
              int.tryParse(state.uri.queryParameters['mediaId'] ?? '') ?? 0;

          final favorite = state.uri.queryParameters['favorite'] == '1';

          return _page(
            context,
            ref,
            state,
            MediaViewerScreen(
              assetId: assetId,

              mediaId: mediaId,

              initialFavorite: favorite,
            ),
          );
        },
      ),

      GoRoute(
        path: '/settings',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) =>
            _page(context, ref, state, const SettingsScreen()),
      ),

      GoRoute(
        path: '/trash',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) =>
            _page(context, ref, state, const TrashScreen()),
      ),

      GoRoute(
        path: '/travel_mode',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) =>
            _page(context, ref, state, const TravelModeListScreen()),
      ),

      GoRoute(
        path: '/travel_mode/edit',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) {
          final id = state.uri.queryParameters['id'];

          return _page(
            context,
            ref,
            state,
            TravelModeEditorScreen(travelModeId: id),
          );
        },
      ),

      GoRoute(
        path: '/story_viewer',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) {
          final path = state.uri.queryParameters['path'] ?? '';

          return _page(
            context,
            ref,
            state,
            StoryViewerScreen(folderPath: path),
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

String postDetailLocation(
  String assetId, {

  required int mediaId,

  bool favorite = false,
}) =>
    '/post_detail?assetId=${Uri.encodeComponent(assetId)}&mediaId=$mediaId&favorite=${favorite ? 1 : 0}';

String mediaViewerLocation(
  String assetId, {

  required int mediaId,

  bool favorite = false,
}) => postDetailLocation(assetId, mediaId: mediaId, favorite: favorite);

String storyViewerLocation(String path) =>
    '/story_viewer?path=${Uri.encodeComponent(path)}';

String travelModeEditorLocation({String? id}) {
  if (id == null || id.isEmpty) return '/travel_mode/edit';

  return '/travel_mode/edit?id=${Uri.encodeComponent(id)}';
}
