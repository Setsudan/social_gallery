import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/domain/models/explore_search_query.dart';
import 'package:social_gallery/features/explore/explore_search_helpers.dart';

/// Top search bar shown while a search filter is active on Gallery / Explore.
class ExploreActiveSearchBar extends StatelessWidget {
  const ExploreActiveSearchBar({
    super.key,
    required this.query,
    required this.onBack,
    required this.onClear,
    this.onTapQuery,
    this.onRemoveLabel,
    this.onRemoveColor,
  });

  final ExploreSearchQuery query;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback? onTapQuery;
  final VoidCallback? onRemoveLabel;
  final VoidCallback? onRemoveColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summary = exploreSearchSummary(
      query: query,
      localize: (key) => _localize(context, key),
    );

    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OneUiSpacing.xs,
            OneUiSpacing.sm,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    tooltip: l10n.tooltipClearSearch,
                    onPressed: onBack,
                  ),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTapQuery,
                        borderRadius: BorderRadius.circular(OneUiRadii.pill),
                        child: Ink(
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius:
                                BorderRadius.circular(OneUiRadii.pill),
                            border: Border.all(
                              color:
                                  colorScheme.outline.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OneUiSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: OneUiSpacing.sm),
                                Expanded(
                                  child: Text(
                                    summary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  tooltip: l10n.tooltipClearSearch,
                                  onPressed: onClear,
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.surfaceContainer,
                                    foregroundColor:
                                        colorScheme.onSurfaceVariant,
                                    minimumSize: const Size(32, 32),
                                    maximumSize: const Size(32, 32),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (query.labels.isNotEmpty || query.color != null) ...[
                const SizedBox(height: OneUiSpacing.sm),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Wrap(
                    spacing: OneUiSpacing.sm,
                    runSpacing: OneUiSpacing.sm,
                    children: [
                      for (final label in query.labels)
                        InputChip(
                          label: Text(
                            _localize(context, exploreSearchLabelKey(label)),
                          ),
                          onDeleted: onRemoveLabel,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (query.color != null)
                        InputChip(
                          avatar: CircleAvatar(
                            backgroundColor:
                                kColorBucketColors[query.color!],
                            radius: 8,
                          ),
                          label: Text(
                            _localize(
                              context,
                              exploreSearchColorKey(query.color!),
                            ),
                          ),
                          onDeleted: onRemoveColor,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _localize(BuildContext context, String key) {
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
}
