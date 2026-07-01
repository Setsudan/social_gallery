import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';

class OrganizeEmptyState extends StatelessWidget {
  const OrganizeEmptyState({
    super.key,
    required this.remainingCount,
    required this.onNextBatch,
    required this.onViewTrash,
    required this.onChangeFilter,
    required this.onReleaseKept,
    this.pendingTrashCount = 0,
  });

  final int remainingCount;
  final int pendingTrashCount;
  final VoidCallback onNextBatch;
  final VoidCallback onViewTrash;
  final VoidCallback onChangeFilter;
  final VoidCallback onReleaseKept;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              remainingCount > 0
                  ? l10n.organizeBatchComplete
                  : l10n.organizeAllCaughtUp,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              remainingCount > 0
                  ? l10n.organizeRemainingItems(remainingCount)
                  : l10n.organizeNoMoreItems,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (remainingCount > 0)
              FilledButton(
                onPressed: onNextBatch,
                child: Text(l10n.organizeLoadNextBatch),
              ),
            if (pendingTrashCount > 0) ...[
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: onViewTrash,
                child: Text(l10n.organizeReviewTrash(pendingTrashCount)),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onChangeFilter,
              child: Text(l10n.organizeChangeFilter),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onReleaseKept,
              child: Text(l10n.organizeReleaseKeptPhotos),
            ),
          ],
        ),
      ),
    );
  }
}
