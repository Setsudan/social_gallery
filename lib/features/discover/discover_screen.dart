import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/features/discover/widgets/deep_organize_tools_list.dart';
import 'package:social_gallery/shared/widgets/async_tab_body.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/shared/navigation/shell_nav_config.dart';
import 'package:social_gallery/shared/navigation/shell_tab_visibility.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/shared/widgets/one_ui/discover_hub_card.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(discoverHubProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context, ref);
    final hubAsync = ref.watch(discoverHubProvider);
    final l10n = context.l10n;

    listenForTabScrollToTop(
      ref,
      kShellTabDiscover,
      _scrollController,
      motion: motion,
    );

    return DeferredShellTab(
      tabIndex: kShellTabDiscover,
      child: Scaffold(
      extendBody: true,
      body: hubAsync.when(
        loading: () => const AsyncTabBody(
          isLoading: true,
          child: SizedBox.shrink(),
        ),
        error: (e, _) => AsyncTabBody(
          error: e,
          isLoading: false,
          empty: EmptyState(
            title: l10n.discoverErrorLoad,
            message: e.toString(),
            icon: Icons.error_outline,
          ),
          child: const SizedBox.shrink(),
        ),
        data: (hub) => RefreshIndicator(
          onRefresh: () => ref.read(discoverHubProvider.notifier).refresh(),
          child: ListView(
            controller: _scrollController,
            cacheExtent: 400,
            padding: FloatingNavInsets.scrollPadding(
              context,
            ).add(const EdgeInsets.all(16)),
            children: [
              OneUiSectionHeader(l10n.discoverSectionOrganize),
              const SizedBox(height: OneUiSpacing.sm),
              StaggeredEntrance(
                index: 0,
                playOnceKey: 'discover_0',
                child: DiscoverHeroCard(
                  unprocessedCount: hub.unprocessedCount,
                  onTap: () => context.push('/organize'),
                ),
              ),
              const SizedBox(height: OneUiSpacing.sectionGap),
              OneUiSectionHeader(l10n.discoverSectionDeepOrganize),
              const SizedBox(height: OneUiSpacing.sm),
              StaggeredEntrance(
                index: 1,
                playOnceKey: 'discover_1',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: l10n.discoverDeepOrganize,
                  subtitle: l10n.discoverDeepOrganizeSubtitle,
                  onTap: () => context.push('/discover/deep-organize'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 2,
                playOnceKey: 'discover_2',
                child: DeepOrganizeToolsList(hub: hub),
              ),
              const SizedBox(height: OneUiSpacing.sectionGap),
              OneUiSectionHeader(l10n.discoverSectionInsights),
              const SizedBox(height: OneUiSpacing.sm),
              StaggeredEntrance(
                index: 5,
                playOnceKey: 'discover_5',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: l10n.discoverShootingStats,
                  subtitle: l10n.discoverShootingStatsSubtitle(hub.processedCount),
                  onTap: () => context.push('/discover/shooting-stats'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 6,
                playOnceKey: 'discover_6',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.favorite_outline),
                  title: l10n.discoverLikesReview,
                  subtitle: l10n.discoverLikesReviewSubtitle(hub.likedCount),
                  onTap: () => context.push('/discover/likes-review'),
                ),
              ),
              const SizedBox(height: OneUiSpacing.sectionGap),
              OneUiSectionHeader(l10n.discoverSectionCleanup),
              const SizedBox(height: OneUiSpacing.sm),
              StaggeredEntrance(
                index: 7,
                playOnceKey: 'discover_7',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.copy_all),
                  title: l10n.discoverDuplicates,
                  subtitle: l10n.discoverDuplicatesSubtitle,
                  onTap: () => context.push('/duplicates'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 71,
                playOnceKey: 'discover_71',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.screenshot_outlined),
                  title: l10n.discoverScreenshotsTitle,
                  subtitle: l10n.discoverScreenshotsSubtitle,
                  onTap: () => context.push('/discover/screenshots'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 72,
                playOnceKey: 'discover_72',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.description_outlined),
                  title: l10n.discoverDocumentsTitle,
                  subtitle: l10n.discoverDocumentsSubtitle,
                  onTap: () => context.push('/discover/documents'),
                ),
              ),
              const SizedBox(height: OneUiSpacing.sectionGap),
              OneUiSectionHeader(l10n.discoverSectionExplore),
              const SizedBox(height: OneUiSpacing.sm),
              StaggeredEntrance(
                index: 8,
                playOnceKey: 'discover_8',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.burst_mode),
                  title: l10n.discoverBurstsTitle,
                  subtitle: l10n.discoverBurstsSubtitle,
                  onTap: () => context.push('/discover/bursts'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 9,
                playOnceKey: 'discover_9',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: l10n.discoverSuggestionsTitle,
                  subtitle: l10n.discoverSuggestionsSubtitle,
                  onTap: () => context.push('/discover/suggestions'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 10,
                playOnceKey: 'discover_10',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.place_outlined),
                  title: l10n.discoverLocationsTitle,
                  subtitle: hub.geotaggedCount > 0
                      ? '${l10n.discoverLocationsSubtitle} - ${l10n.locationsGeotaggedBadge(hub.geotaggedCount)}'
                      : l10n.discoverLocationsSubtitle,
                  onTap: () => context.push('/discover/locations'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
