import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

class OrganizeStatsSheet extends StatelessWidget {
  const OrganizeStatsSheet({super.key, required this.stats});

  final OrganizeStats stats;

  static Future<void> show(BuildContext context, OrganizeStats stats) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrganizeStatsSheet(stats: stats),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Organize stats',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _StatRow(label: 'Processed', value: '${stats.processedCount}'),
            _StatRow(label: 'Deleted', value: '${stats.deletedCount}'),
            _StatRow(label: 'Liked', value: '${stats.likedCount}'),
            _StatRow(
              label: 'Space saved',
              value: _formatBytes(stats.savedBytes),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                context.push('/discover/shooting-stats');
              },
              child: const Text('Shooting stats'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                context.push('/discover/deep-organize');
              },
              child: const Text('Deep organize'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                context.push('/discover/likes-review');
              },
              child: const Text('Likes review'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
