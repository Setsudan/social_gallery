import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
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
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.organizeStatsTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _StatRow(label: l10n.organizeStatProcessed, value: '${stats.processedCount}'),
            _StatRow(label: l10n.organizeStatDeleted, value: '${stats.deletedCount}'),
            _StatRow(label: l10n.organizeStatLiked, value: '${stats.likedCount}'),
            _StatRow(
              label: l10n.organizeStatSpaceSaved,
              value: _formatBytes(stats.savedBytes),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                context.push('/discover/shooting-stats');
              },
              child: Text(l10n.discoverShootingStats),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                context.push('/discover/deep-organize');
              },
              child: Text(l10n.discoverDeepOrganize),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                Navigator.pop(context);
                context.push('/discover/likes-review');
              },
              child: Text(l10n.discoverLikesReview),
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
