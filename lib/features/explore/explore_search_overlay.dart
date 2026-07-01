import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/recent_search.dart';
import 'package:social_gallery/features/explore/explore_recent_searches_provider.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class ExploreSearchOverlay extends ConsumerStatefulWidget {
  const ExploreSearchOverlay({super.key, this.initialQuery = ''});

  final String initialQuery;

  static Future<String?> show(
    BuildContext context, {
    String initialQuery = '',
  }) {
    final container = ProviderScope.containerOf(context);
    container.read(exploreSearchOverlayOpenProvider.notifier).state = true;

    return Navigator.of(context)
        .push<String>(
          PageRouteBuilder(
            opaque: true,
            transitionDuration: const Duration(milliseconds: 350),
            reverseTransitionDuration: const Duration(milliseconds: 250),
            pageBuilder: (context, animation, secondaryAnimation) {
              return ExploreSearchOverlay(initialQuery: initialQuery);
            },
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              );
            },
          ),
        )
        .whenComplete(() {
      container.read(exploreSearchOverlayOpenProvider.notifier).state = false;
    });
  }

  @override
  ConsumerState<ExploreSearchOverlay> createState() =>
      _ExploreSearchOverlayState();
}

class _ExploreSearchOverlayState extends ConsumerState<ExploreSearchOverlay> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _focusNode = FocusNode();
    _controller.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onQueryChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _dismiss({required bool clearActiveSearch}) {
    AppHaptics.light();
    Navigator.of(context).pop(clearActiveSearch ? '' : null);
  }

  void _submit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    AppHaptics.light();
    Navigator.of(context).pop(trimmed);
  }

  List<String> _folderSuggestions(AsyncValue<List<FolderInfo>> foldersAsync) {
    final folders = foldersAsync.valueOrNull ?? const <FolderInfo>[];
    final names = folders
        .where((folder) => folder.mediaCount > 0)
        .map((folder) => folder.name)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final typed = _controller.text.trim().toLowerCase();
    final filtered = typed.isEmpty
        ? names
        : names
            .where((name) => name.toLowerCase().contains(typed))
            .toList();
    return filtered.take(12).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final recentSearches = ref.watch(recentSearchesProvider);
    final foldersAsync = ref.watch(allFoldersProvider);
    final folderSuggestions = _folderSuggestions(foldersAsync);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _dismiss(clearActiveSearch: true);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colorScheme.surface.withValues(alpha: 0.97),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => _dismiss(clearActiveSearch: true),
          ),
        ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.sm,
                OneUiSpacing.pageHorizontal,
                OneUiSpacing.lg,
              ),
              children: [
                Text(
                  l10n.searchAlbumsAndFolders,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: OneUiSpacing.md),
                if (foldersAsync.isLoading && folderSuggestions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: OneUiSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (folderSuggestions.isEmpty)
                  Text(
                    l10n.searchNoMatchingAlbums,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: OneUiSpacing.sm,
                    runSpacing: OneUiSpacing.sm,
                    children: folderSuggestions.map((label) {
                      return ActionChip(
                        label: Text(label),
                        onPressed: () => _submit(label),
                        backgroundColor: colorScheme.surfaceContainer,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(OneUiRadii.chip),
                        ),
                      );
                    }).toList(),
                  ),
                if (recentSearches.isNotEmpty) ...[
                  const SizedBox(height: OneUiSpacing.xl),
                  Row(
                    children: [
                      Text(
                        l10n.searchRecentSearches,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          AppHaptics.light();
                          ref.read(recentSearchesProvider.notifier).clearAll();
                        },
                        child: Text(l10n.searchClearAll),
                      ),
                    ],
                  ),
                  const SizedBox(height: OneUiSpacing.sm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(OneUiRadii.xl),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < recentSearches.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: 64,
                              color: colorScheme.outline.withValues(alpha: 0.3),
                            ),
                          _RecentSearchTile(
                            entry: recentSearches[i],
                            onTap: () => _submit(recentSearches[i].query),
                            onRemove: () {
                              AppHaptics.light();
                              ref
                                  .read(recentSearchesProvider.notifier)
                                  .remove(recentSearches[i].query);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.md + bottomInset + bottomPadding,
            ),
            child: _GradientSearchBar(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: _submit,
              onClear: () {
                if (_controller.text.isEmpty) {
                  _dismiss(clearActiveSearch: true);
                  return;
                }
                _controller.clear();
                _focusNode.requestFocus();
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final RecentSearch entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OneUiRadii.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OneUiSpacing.md,
          vertical: OneUiSpacing.md,
        ),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: entry.thumbnailUri != null
                    ? MediaThumbnail(
                        assetId: entry.thumbnailUri!,
                        maxThumbnailEdge: 80,
                      )
                    : ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: OneUiSpacing.md),
            Expanded(
              child: Text(
                entry.query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientSearchBar extends StatelessWidget {
  const _GradientSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.primary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OneUiRadii.pill),
        gradient: LinearGradient(
          colors: [
            accent,
            colorScheme.tertiary,
            colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: Material(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(OneUiRadii.pill - 1.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: onSubmitted,
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) {
                    if (controller.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: l10n.tooltipClear,
                      onPressed: onClear,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                    );
                  },
                ),
                Icon(
                  Icons.mic_none_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
