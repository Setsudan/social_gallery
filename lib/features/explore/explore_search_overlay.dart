import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/analysis/media_tagging_controller.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/search/explore_query_parser.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/recent_search.dart';
import 'package:social_gallery/features/explore/explore_recent_searches_provider.dart';
import 'package:social_gallery/features/explore/explore_search_helpers.dart';
import 'package:social_gallery/shared/navigation/tab_scroll_to_top.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class ExploreSearchOverlay extends ConsumerStatefulWidget {
  const ExploreSearchOverlay({super.key, this.initialQuery = const ExploreSearchQuery()});

  final ExploreSearchQuery initialQuery;

  static Future<ExploreSearchQuery?> show(
    BuildContext context, {
    ExploreSearchQuery initialQuery = const ExploreSearchQuery(),
  }) {
    final container = ProviderScope.containerOf(context);
    container.read(exploreSearchOverlayOpenProvider.notifier).state = true;

    return Navigator.of(context)
        .push<ExploreSearchQuery>(
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
  String? _selectedLabel;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery.text);
    _selectedLabel = widget.initialQuery.label;
    _selectedColor = widget.initialQuery.color;
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
    Navigator.of(context).pop(
      clearActiveSearch ? const ExploreSearchQuery() : null,
    );
  }

  ExploreSearchQuery _buildQuery() {
    final typed = _controller.text.trim();
    final parsed = typed.isEmpty
        ? const ExploreSearchQuery()
        : ExploreQueryParser().parse(typed);
    var query = parsed;
    if (_selectedLabel != null && _selectedLabel!.isNotEmpty) {
      final labels = {...query.labels, _selectedLabel!}.toList();
      query = query.copyWith(labels: labels);
    }
    if (_selectedColor != null && _selectedColor!.isNotEmpty) {
      query = query.copyWith(color: _selectedColor);
    }
    return query;
  }

  void _submit([String? textOverride]) {
    if (textOverride != null) {
      _controller.text = textOverride;
    }
    final query = _buildQuery();
    if (query.isEmpty) return;
    AppHaptics.light();
    Navigator.of(context).pop(query);
  }

  void _submitLabel(String label) {
    setState(() {
      _selectedLabel = label;
      _controller.clear();
    });
    AppHaptics.light();
    Navigator.of(context).pop(
      ExploreSearchQuery(labels: [label]),
    );
  }

  void _submitColor(String color) {
    setState(() => _selectedColor = color);
    AppHaptics.light();
    Navigator.of(context).pop(
      ExploreSearchQuery(color: color),
    );
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

  String _localize(String key) {
    final l10n = context.l10n;
    return switch (key) {
      'searchChipCat' => l10n.searchChipCat,
      'searchChipDog' => l10n.searchChipDog,
      'searchChipPerson' => l10n.searchChipPerson,
      'searchChipFood' => l10n.searchChipFood,
      'searchChipCar' => l10n.searchChipCar,
      'searchChipFlower' => l10n.searchChipFlower,
      'searchChipBottle' => l10n.searchChipBottle,
      'searchChipBird' => l10n.searchChipBird,
      'searchChipBeach' => l10n.searchChipBeach,
      'searchChipMountain' => l10n.searchChipMountain,
      'searchColorRed' => l10n.searchColorRed,
      'searchColorOrange' => l10n.searchColorOrange,
      'searchColorYellow' => l10n.searchColorYellow,
      'searchColorGreen' => l10n.searchColorGreen,
      'searchColorTeal' => l10n.searchColorTeal,
      'searchColorBlue' => l10n.searchColorBlue,
      'searchColorPurple' => l10n.searchColorPurple,
      'searchColorPink' => l10n.searchColorPink,
      'searchColorBrown' => l10n.searchColorBrown,
      'searchColorBlack' => l10n.searchColorBlack,
      'searchColorWhite' => l10n.searchColorWhite,
      'searchColorGray' => l10n.searchColorGray,
      _ => key,
    };
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
    final tagging = ref.watch(mediaTaggingControllerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _dismiss(clearActiveSearch: true);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 64,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => _dismiss(clearActiveSearch: true),
          ),
          titleSpacing: 0,
          title: _SearchField(
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
          actions: [
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                final hasText = _controller.text.trim().isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(right: OneUiSpacing.sm),
                  child: TextButton(
                    onPressed: hasText ? () => _submit() : null,
                    child: Text(l10n.tooltipSearch),
                  ),
                );
              },
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.sm,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.lg + bottomInset + bottomPadding,
          ),
          children: [
            if (tagging.isScanning) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(OneUiRadii.sm),
                child: LinearProgressIndicator(
                  value: tagging.progress,
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: OneUiSpacing.sm),
              Text(
                l10n.searchIndexingProgress(tagging.scanned, tagging.total),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: OneUiSpacing.lg),
            ],
            Text(
              l10n.searchObjectsAndAnimals,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: OneUiSpacing.md),
            Wrap(
              spacing: OneUiSpacing.sm,
              runSpacing: OneUiSpacing.sm,
              children: kExploreLabelChips.entries.map((entry) {
                final label = entry.value;
                return ActionChip(
                  label: Text(_localize(entry.key)),
                  onPressed: () => _submitLabel(label),
                  backgroundColor: colorScheme.surfaceContainer,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(OneUiRadii.chip),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: OneUiSpacing.xl),
            Text(
              l10n.searchFilterByColor,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: OneUiSpacing.md),
            Wrap(
              spacing: OneUiSpacing.sm,
              runSpacing: OneUiSpacing.sm,
              children: searchableColorBuckets.map((colorId) {
                final swatch = kColorBucketColors[colorId]!;
                final selected = _selectedColor == colorId;
                return Tooltip(
                  message: _localize(exploreSearchColorKey(colorId)),
                  child: InkWell(
                    onTap: () => _submitColor(colorId),
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: swatch,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.35),
                          width: selected ? 2.5 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.28),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: OneUiSpacing.xl),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
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

/// One UI pill search field used in the Explore search overlay app bar.
class _SearchField extends StatelessWidget {
  const _SearchField({
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(OneUiRadii.pill),
            border: Border.all(
              color: focused
                  ? colorScheme.primary.withValues(alpha: 0.55)
                  : colorScheme.outline.withValues(alpha: 0.22),
              width: focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: OneUiSpacing.md),
              Icon(
                Icons.search_rounded,
                size: 22,
                color: focused
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: OneUiSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  style: theme.textTheme.bodyLarge,
                  cursorColor: colorScheme.primary,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.65,
                      ),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.text.isEmpty) {
                    return const SizedBox(width: OneUiSpacing.sm);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: OneUiSpacing.xs),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: l10n.tooltipClear,
                      onPressed: onClear,
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainer,
                        foregroundColor: colorScheme.onSurfaceVariant,
                        minimumSize: const Size(32, 32),
                        maximumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
