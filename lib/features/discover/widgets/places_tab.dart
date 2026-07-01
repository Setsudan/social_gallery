import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/router.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/domain/models/place_group.dart';
import 'package:social_gallery/features/discover/locations_providers.dart';
import 'package:social_gallery/shared/widgets/album_cover_tile.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';

class PlacesTab extends ConsumerStatefulWidget {
  const PlacesTab({super.key});

  @override
  ConsumerState<PlacesTab> createState() => _PlacesTabState();
}

class _PlacesTabState extends ConsumerState<PlacesTab> {
  CountryPlaceGroup? _selectedCountry;

  void _selectCountry(CountryPlaceGroup country) {
    setState(() => _selectedCountry = country);
  }

  void _clearCountry() {
    setState(() => _selectedCountry = null);
  }

  void _openPlace(PlaceGroup place) {
    context.push(
      placeMediaLocation(place.countryName, place.locality),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(countryPlaceGroupsProvider);
    final l10n = context.l10n;

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(
        title: l10n.locationsErrorTitle,
        message: l10n.locationsErrorMessage,
        icon: Icons.error_outline,
      ),
      data: (countries) {
        if (countries.isEmpty) {
          return EmptyState(
            title: l10n.locationsEmptyTitle,
            message: l10n.locationsEmptyMessage,
            icon: Icons.place_outlined,
          );
        }

        if (_selectedCountry != null) {
          return _CityGrid(
            country: _selectedCountry!,
            onBack: _clearCountry,
            onTapPlace: _openPlace,
          );
        }

        return _CountryGrid(
          countries: countries,
          onTapCountry: _selectCountry,
        );
      },
    );
  }
}

class _CountryGrid extends StatelessWidget {
  const _CountryGrid({
    required this.countries,
    required this.onTapCountry,
  });

  final List<CountryPlaceGroup> countries;
  final void Function(CountryPlaceGroup country) onTapCountry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const columns = 2;

    return CustomScrollView(
      cacheExtent: 600,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.md,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
            ),
            child: Text(
              l10n.locationsCountry,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            OneUiSpacing.pageHorizontal,
            0,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.md,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: OneUiSpacing.sm,
              mainAxisSpacing: OneUiSpacing.sm,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final country = countries[index];
                return StaggeredEntrance(
                  index: index,
                  playOnceKey: 'place_country_${country.countryName}',
                  child: AlbumCoverTile(
                    title: country.countryName,
                    coverUri: country.coverItem?.uri,
                    itemCount: country.count,
                    onTap: () => onTapCountry(country),
                  ),
                );
              },
              childCount: countries.length,
              addRepaintBoundaries: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _CityGrid extends StatelessWidget {
  const _CityGrid({
    required this.country,
    required this.onBack,
    required this.onTapPlace,
  });

  final CountryPlaceGroup country;
  final VoidCallback onBack;
  final void Function(PlaceGroup place) onTapPlace;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const columns = 2;

    return CustomScrollView(
      cacheExtent: 600,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
                Expanded(
                  child: Text(
                    country.countryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              0,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
            ),
            child: Text(
              l10n.locationsCity,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            OneUiSpacing.pageHorizontal,
            0,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.md,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: OneUiSpacing.sm,
              mainAxisSpacing: OneUiSpacing.sm,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final place = country.cities[index];
                return StaggeredEntrance(
                  index: index,
                  playOnceKey:
                      'place_city_${country.countryName}_${place.locality}',
                  child: AlbumCoverTile(
                    title: place.locality,
                    coverUri: place.coverItem?.uri,
                    itemCount: place.count,
                    onTap: () => onTapPlace(place),
                  ),
                );
              },
              childCount: country.cities.length,
              addRepaintBoundaries: true,
            ),
          ),
        ),
      ],
    );
  }
}
