import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/features/discover/location_index_controller.dart';
import 'package:social_gallery/features/discover/widgets/map_tab.dart';
import 'package:social_gallery/features/discover/widgets/places_tab.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';

class LocationsScreen extends ConsumerStatefulWidget {
  const LocationsScreen({super.key});

  @override
  ConsumerState<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends ConsumerState<LocationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationIndexControllerProvider.notifier).ensureStarted();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final indexState = ref.watch(locationIndexControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.discoverLocationsTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.locationsTabPlaces),
            Tab(text: l10n.locationsTabMap),
          ],
        ),
      ),
      body: _buildBody(context, indexState),
    );
  }

  Widget _buildBody(BuildContext context, LocationIndexState indexState) {
    final l10n = context.l10n;

    if (indexState.hasError) {
      return EmptyState(
        title: l10n.locationsErrorTitle,
        message: l10n.locationsErrorMessage,
        icon: Icons.error_outline,
      );
    }

    if (indexState.isIndexing && !indexState.isComplete) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (indexState.total > 0)
                LinearProgressIndicator(value: indexState.progress)
              else
                const LinearProgressIndicator(),
              const SizedBox(height: OneUiSpacing.md),
              Text(
                indexState.isBackfilling
                    ? (indexState.total > 0
                        ? l10n.locationsBackfillProgress(
                            indexState.indexed,
                            indexState.total,
                          )
                        : l10n.locationsBackfillPreparing)
                    : (indexState.total > 0
                        ? l10n.locationsIndexing(
                            indexState.indexed,
                            indexState.total,
                          )
                        : l10n.locationsIndexingPreparing),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return IndexedStack(
      index: _tabController.index,
      children: const [
        PlacesTab(),
        MapTab(),
      ],
    );
  }
}
