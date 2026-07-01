import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';

/// Top search bar shown while a search filter is active on Gallery / Explore.
class ExploreActiveSearchBar extends StatelessWidget {
  const ExploreActiveSearchBar({
    super.key,
    required this.query,
    required this.onBack,
    required this.onClear,
    this.onTapQuery,
  });

  final String query;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback? onTapQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            OneUiSpacing.xs,
            OneUiSpacing.sm,
            OneUiSpacing.pageHorizontal,
            OneUiSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.tooltipClearSearch,
                onPressed: onBack,
              ),
              Expanded(
                child: InkWell(
                  onTap: onTapQuery,
                  borderRadius: BorderRadius.circular(OneUiRadii.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OneUiSpacing.md,
                      vertical: OneUiSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(OneUiRadii.pill),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: OneUiSpacing.sm),
                        Expanded(
                          child: Text(
                            query,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          tooltip: l10n.tooltipClearSearch,
                          onPressed: onClear,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
