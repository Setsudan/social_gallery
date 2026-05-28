import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/motion/staggered_entrance.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _scrollController = ScrollController();
  int _groupCount = 0;
  int _itemCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final candidates = await ref
        .read(mediaRepositoryProvider)
        .getPotentialDuplicates();
    final groups = ref.read(findDuplicateGroupsProvider)(candidates);
    final items = groups.fold<int>(0, (sum, g) => sum + g.count);
    setState(() {
      _groupCount = groups.length;
      _itemCount = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context, ref);
    listenForTabScrollToTop(
      ref,
      kShellTabDiscover,
      _scrollController,
      motion: motion,
    );

    return Scaffold(
      extendBody: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                controller: _scrollController,
                padding: FloatingNavInsets.scrollPadding(
                  context,
                ).add(const EdgeInsets.all(16)),
                children: [
                  const OneUiPageHeader(
                    title: 'Discover',
                    subtitle:
                        'Tools to clean up and explore your library on device.',
                  ),
                  const OneUiSectionHeader('Cleanup'),
                  const SizedBox(height: OneUiSpacing.sm),
                  if (_groupCount == 0)
                    const StaggeredEntrance(
                      index: 0,
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
                      index: 0,
                      child: _DiscoverHubCard(
                        leading: const Icon(Icons.copy_all),
                        title: 'Duplicates',
                        subtitle: '$_groupCount groups, $_itemCount items',
                        onTap: () => context.push('/duplicates'),
                      ),
                    ),
                  const SizedBox(height: OneUiSpacing.sectionGap),
                  const OneUiSectionHeader('Explore'),
                  const SizedBox(height: OneUiSpacing.sm),
                  StaggeredEntrance(
                    index: 1,
                    child: _DiscoverHubCard(
                      leading: const Icon(Icons.burst_mode),
                      title: 'Bursts',
                      subtitle: 'Rapid-fire photo groups',
                      onTap: () => context.push('/discover/bursts'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StaggeredEntrance(
                    index: 2,
                    child: _DiscoverHubCard(
                      leading: const Icon(Icons.auto_awesome_outlined),
                      title: 'Smart suggestions',
                      subtitle: 'Album and cleanup ideas',
                      onTap: () => context.push('/discover/suggestions'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  StaggeredEntrance(
                    index: 3,
                    child: _DiscoverHubCard(
                      leading: const Icon(Icons.place_outlined),
                      title: 'Locations',
                      subtitle: 'Photos grouped by place',
                      onTap: () => context.push('/discover/locations'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DiscoverHubCard extends StatelessWidget {
  const _DiscoverHubCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.card),
        ),
        child: ListTile(
          leading: leading,
          title: Text(title, style: Theme.of(context).textTheme.titleSmall),
          subtitle: Text(subtitle),
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
