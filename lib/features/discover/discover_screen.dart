import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/features/discover/widgets/deep_organize_tools_list.dart';
import 'package:social_gallery/shared/widgets/async_tab_body.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
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

    listenForTabScrollToTop(
      ref,
      kShellTabDiscover,
      _scrollController,
      motion: motion,
    );

    return Scaffold(
      extendBody: true,
      body: hubAsync.when(
        loading: () => const AsyncTabBody(
          isLoading: true,
          header: OneUiPageHeader(title: 'Discover'),
          child: SizedBox.shrink(),
        ),
        error: (e, _) => AsyncTabBody(
          error: e,
          isLoading: false,
          header: const OneUiPageHeader(title: 'Discover'),
          empty: EmptyState(
            title: 'Could not load discover',
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
              const OneUiPageHeader(
                title: 'Discover',
                subtitle:
                    'Organize memories and clean up your library on device.',
              ),
              const OneUiSectionHeader('Organize'),
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
              const OneUiSectionHeader('Deep organize'),
              const SizedBox(height: OneUiSpacing.sm),
              StaggeredEntrance(
                index: 1,
                playOnceKey: 'discover_1',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.document_scanner_outlined),
                  title: 'Deep organize',
                  subtitle: 'Scan, similar photos, low quality, compression',
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
              const OneUiSectionHeader('Insights'),
              const SizedBox(height: OneUiSpacing.sm),
              StaggeredEntrance(
                index: 5,
                playOnceKey: 'discover_5',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.bar_chart_outlined),
                  title: 'Shooting stats',
                  subtitle: '${hub.processedCount} items organized so far',
                  onTap: () => context.push('/discover/shooting-stats'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 6,
                playOnceKey: 'discover_6',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.favorite_outline),
                  title: 'Likes review',
                  subtitle: '${hub.likedCount} favorites',
                  onTap: () => context.push('/discover/likes-review'),
                ),
              ),
              const SizedBox(height: OneUiSpacing.sectionGap),
              const OneUiSectionHeader('Cleanup'),
              const SizedBox(height: OneUiSpacing.sm),
              if (hub.duplicateGroupCount == 0)
                StaggeredEntrance(
                  index: 7,
                  playOnceKey: 'discover_7',
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('No duplicates found'),
                      subtitle: Text(
                        'Your library looks clean based on file size and dimensions.',
                      ),
                    ),
                  ),
                )
              else
                StaggeredEntrance(
                  index: 7,
                  playOnceKey: 'discover_7',
                  child: DiscoverHubCard(
                    leading: const Icon(Icons.copy_all),
                    title: 'Duplicates',
                    subtitle:
                        '${hub.duplicateGroupCount} groups, ${hub.duplicateItemCount} items',
                    onTap: () => context.push('/duplicates'),
                  ),
                ),
              const SizedBox(height: OneUiSpacing.sectionGap),
              const OneUiSectionHeader('Explore'),
              const SizedBox(height: OneUiSpacing.sm),
              StaggeredEntrance(
                index: 8,
                playOnceKey: 'discover_8',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.burst_mode),
                  title: 'Bursts',
                  subtitle: 'Rapid-fire photo groups',
                  onTap: () => context.push('/discover/bursts'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 9,
                playOnceKey: 'discover_9',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: 'Smart suggestions',
                  subtitle: 'Album and cleanup ideas',
                  onTap: () => context.push('/discover/suggestions'),
                ),
              ),
              const SizedBox(height: 8),
              StaggeredEntrance(
                index: 10,
                playOnceKey: 'discover_10',
                child: DiscoverHubCard(
                  leading: const Icon(Icons.place_outlined),
                  title: 'Locations',
                  subtitle: 'Photos grouped by place',
                  onTap: () => context.push('/discover/locations'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
