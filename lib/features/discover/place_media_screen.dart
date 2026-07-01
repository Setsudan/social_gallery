import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/location/location_clustering.dart';
import 'package:social_gallery/features/discover/locations_providers.dart';
import 'package:social_gallery/shared/navigation/media_viewer_session.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_grid.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class PlaceMediaScreen extends ConsumerWidget {
  const PlaceMediaScreen({
    super.key,
    required this.countryName,
    required this.locality,
  });

  final String countryName;
  final String locality;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(locationLibrarySnapshotProvider);
    final l10n = context.l10n;
    final title = locality == countryName ? countryName : '$locality, $countryName';

    return snapshotAsync.when(
      loading: () => OneUiSubpageScaffold(
        title: l10n.discoverLocationsTitle,
        isLoading: true,
        body: const SizedBox.shrink(),
      ),
      error: (e, _) => OneUiSubpageScaffold(
        title: l10n.discoverLocationsTitle,
        error: e,
        body: const SizedBox.shrink(),
      ),
      data: (snapshot) {
        final items = filterPlaceMedia(
          items: snapshot.items,
          placesByKey: snapshot.placesByKey,
          countryName: countryName,
          locality: locality,
        );

        return OneUiSubpageScaffold(
          title: l10n.discoverLocationsTitle,
          appBarTitle: title,
          subtitle: l10n.locationsPhotoCount(items.length),
          isEmpty: items.isEmpty,
          empty: EmptyState(
            title: l10n.locationsEmptyTitle,
            message: l10n.locationsEmptyMessage,
            icon: Icons.place_outlined,
          ),
          body: MediaGrid(
            items: items,
            onTap: (item) => openMediaViewer(
              context,
              ref,
              items: items,
              item: item,
            ),
          ),
        );
      },
    );
  }
}
