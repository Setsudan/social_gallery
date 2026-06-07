import 'package:flutter/material.dart';

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
                  ? 'Batch complete'
                  : 'All caught up',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              remainingCount > 0
                  ? '$remainingCount items still match your filters.'
                  : 'No more items match the current filters.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (remainingCount > 0)
              FilledButton(
                onPressed: onNextBatch,
                child: const Text('Load next batch'),
              ),
            if (pendingTrashCount > 0) ...[
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: onViewTrash,
                child: Text('Review trash ($pendingTrashCount)'),
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onChangeFilter,
              child: const Text('Change filter'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onReleaseKept,
              child: const Text('Release kept photos'),
            ),
          ],
        ),
      ),
    );
  }
}
