import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:social_gallery/core/animation/page_transitions.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';

import 'package:social_gallery/features/discover/duplicate_review_screen.dart';

import 'package:social_gallery/features/discover/duplicates_screen.dart';

import 'package:social_gallery/features/discover/discover_stub_screen.dart';
import 'package:social_gallery/features/discover/locations_screen.dart';
import 'package:social_gallery/features/discover/place_media_screen.dart';

import 'package:social_gallery/features/albums/locked_albums_screen.dart';
import 'package:social_gallery/features/shell/explore_branch_screen.dart';

import 'package:social_gallery/features/folder_management/folder_management_screen.dart';

import 'package:social_gallery/features/folder_profile/folder_profile_screen.dart';

import 'package:social_gallery/features/deep_organize/compression_screen.dart';
import 'package:social_gallery/features/deep_organize/deep_organize_screen.dart';
import 'package:social_gallery/features/deep_organize/likes_review_screen.dart';
import 'package:social_gallery/features/deep_organize/low_quality_screen.dart';
import 'package:social_gallery/features/deep_organize/shooting_stats_screen.dart';
import 'package:social_gallery/features/deep_organize/similar_photos_screen.dart';
import 'package:social_gallery/features/discover/discover_screen.dart';
import 'package:social_gallery/features/organize/organize_screen.dart';

import 'package:social_gallery/features/media_viewer/media_viewer_screen.dart';

import 'package:social_gallery/features/post_detail/post_detail_screen.dart';

import 'package:social_gallery/features/shell/home_branch_screen.dart';

import 'package:social_gallery/features/shell/main_shell.dart';

import 'package:social_gallery/features/startup/startup_screen.dart';

import 'package:social_gallery/features/archive/desktop_archive_screen.dart';
import 'package:social_gallery/features/settings/settings_screen.dart';

import 'package:social_gallery/features/trash/trash_screen.dart';

import 'package:social_gallery/features/story_viewer/story_viewer_screen.dart';

import 'package:social_gallery/features/travel_mode/travel_mode_editor_screen.dart';

import 'package:social_gallery/features/travel_mode/travel_mode_list_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Builds a page with app-wide transition animation from settings.
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

/// go_router setup: startup gate, three-tab shell, and full-screen modal routes.
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
                    _page(context, ref, state, const HomeBranchScreen()),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',

                pageBuilder: (context, state) =>
                    _page(context, ref, state, const ExploreBranchScreen()),
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

        ],
      ),

      GoRoute(
        path: '/locked_albums',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) =>
            _page(context, ref, state, const LockedAlbumsScreen()),
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
          DiscoverStubScreen(
            title: context.l10n.discoverBurstsTitle,
            message: context.l10n.discoverBurstsMessage,
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
          DiscoverStubScreen(
            title: context.l10n.discoverSuggestionsTitle,
            message: context.l10n.discoverSuggestionsMessage,
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
          const LocationsScreen(),
        ),
      ),

      GoRoute(
        path: '/discover/locations/place',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) {
          final country = state.uri.queryParameters['country'] ?? '';
          final locality = state.uri.queryParameters['locality'] ?? '';
          return _page(
            context,
            ref,
            state,
            PlaceMediaScreen(
              countryName: country,
              locality: locality,
            ),
          );
        },
      ),

      GoRoute(
        path: '/organize',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(context, ref, state, const OrganizeScreen()),
      ),

      GoRoute(
        path: '/discover/deep-organize',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(context, ref, state, const DeepOrganizeScreen()),
      ),

      GoRoute(
        path: '/discover/similar',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(context, ref, state, const SimilarPhotosScreen()),
      ),

      GoRoute(
        path: '/discover/low-quality',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(context, ref, state, const LowQualityScreen()),
      ),

      GoRoute(
        path: '/discover/compression',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(context, ref, state, const CompressionScreen()),
      ),

      GoRoute(
        path: '/discover/shooting-stats',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(context, ref, state, const ShootingStatsScreen()),
      ),

      GoRoute(
        path: '/discover/likes-review',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            _page(context, ref, state, const LikesReviewScreen()),
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
        path: '/desktop-archive',

        parentNavigatorKey: _rootNavigatorKey,

        pageBuilder: (context, state) =>
            _page(context, ref, state, const DesktopArchiveScreen()),
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

const lockedAlbumsLocation = '/locked_albums';

/// Typed route to a folder profile screen.
String folderProfileLocation(String path) =>
    '/folder_profile?path=${Uri.encodeComponent(path)}';

/// Typed route to review one duplicate group by [groupKey].
String duplicateReviewLocation(String groupKey) =>
    '/duplicate_review?key=${Uri.encodeComponent(groupKey)}';

/// Typed route to post detail (feed tap). [favorite] seeds the heart state.
String postDetailLocation(
  String assetId, {

  required int mediaId,

  bool favorite = false,
}) =>
    '/post_detail?assetId=${Uri.encodeComponent(assetId)}&mediaId=$mediaId&favorite=${favorite ? 1 : 0}';

/// Alias for [postDetailLocation]; used by fullscreen media viewer entry points.
String mediaViewerLocation(
  String assetId, {

  required int mediaId,

  bool favorite = false,
}) => postDetailLocation(assetId, mediaId: mediaId, favorite: favorite);

/// Typed route to story viewer for one folder.
String storyViewerLocation(String path) =>
    '/story_viewer?path=${Uri.encodeComponent(path)}';

/// Typed route to create or edit a travel mode ([id] null for new).
String travelModeEditorLocation({String? id}) {
  if (id == null || id.isEmpty) return '/travel_mode/edit';

  return '/travel_mode/edit?id=${Uri.encodeComponent(id)}';
}

/// Typed route to geotagged media for a country and city/locality.
String placeMediaLocation(String country, String locality) =>
    '/discover/locations/place?country=${Uri.encodeComponent(country)}&locality=${Uri.encodeComponent(locality)}';
