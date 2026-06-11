import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
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

    return queueAsync.when(
      loading: () => OneUiSubpageScaffold(
        title: 'Low quality',
        isLoading: true,
        body: const SizedBox.shrink(),
      ),
      error: (e, _) => OneUiSubpageScaffold(
        title: 'Low quality',
        error: e,
        body: const SizedBox.shrink(),
      ),
      data: (queue) {
        if (queue.isEmpty) {
          return OneUiSubpageScaffold(
            title: 'Low quality',
            subtitle: 'Run a scan from Deep organize first.',
            isEmpty: true,
            empty: const EmptyState(
              title: 'No low-quality items',
              icon: Icons.blur_off,
            ),
            body: const SizedBox.shrink(),
          );
        }

        final current = queue[_index.clamp(0, queue.length - 1)];
        return OneUiSubpageScaffold(
          title: 'Low quality review',
          subtitle: 'Review flagged shots and delete what you do not need.',
          appBarTitle: '${_index + 1} / ${queue.length}',
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
                            child: const Text('Keep'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _deleteCurrent(current),
                            child: const Text('Delete'),
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
