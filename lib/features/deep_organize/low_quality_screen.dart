import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/pagination/paginated_list_notifier.dart';
import 'package:social_gallery/shared/widgets/empty_state.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class LowQualityScreen extends ConsumerStatefulWidget {
  const LowQualityScreen({super.key});

  @override
  ConsumerState<LowQualityScreen> createState() => _LowQualityScreenState();
}

class _LowQualityScreenState extends ConsumerState<LowQualityScreen> {
  int _index = 0;

  Future<void> _deleteCurrent(LowQualityEntry entry) async {
    await ref.read(mediaRepositoryProvider).deleteFromDevice([entry.item]);
    invalidateAnalysisProviders(ref);
    refreshFeedProviders(ref);
    setState(() => _index = 0);
  }

  void _skip(int length) {
    if (_index < length - 1) {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(lowQualityQueueProvider);
    final l10n = context.l10n;

    return queueAsync.when(
      loading: () => OneUiSubpageScaffold(
        title: l10n.deepOrganizeLowQuality,
        isLoading: true,
        body: const SizedBox.shrink(),
      ),
      error: (e, _) => OneUiSubpageScaffold(
        title: l10n.deepOrganizeLowQuality,
        error: e,
        body: const SizedBox.shrink(),
      ),
      data: (queue) {
        if (queue.isEmpty) {
          return OneUiSubpageScaffold(
            title: l10n.deepOrganizeLowQuality,
            subtitle: l10n.deepOrganizeRunScanFirst,
            isEmpty: true,
            empty: EmptyState(
              title: l10n.lowQualityEmptyTitle,
              icon: Icons.blur_off,
            ),
            body: const SizedBox.shrink(),
          );
        }

        final current = queue[_index.clamp(0, queue.length - 1)];
        return OneUiSubpageScaffold(
          title: l10n.lowQualityReviewTitle,
          subtitle: l10n.lowQualityReviewSubtitle,
          appBarTitle: l10n.lowQualityProgress(_index + 1, queue.length),
          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MediaThumbnail(assetId: current.item.uri),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(current.item.displayName),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: current.reasons
                          .map((r) => Chip(label: Text(r)))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _skip(queue.length),
                            child: Text(l10n.actionKeep),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _deleteCurrent(current),
                            child: Text(l10n.actionDelete),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
