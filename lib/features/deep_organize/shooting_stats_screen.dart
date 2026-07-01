import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class ShootingStatsScreen extends ConsumerStatefulWidget {
  const ShootingStatsScreen({super.key});

  @override
  ConsumerState<ShootingStatsScreen> createState() =>
      _ShootingStatsScreenState();
}

class _ShootingStatsScreenState extends ConsumerState<ShootingStatsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  String _formatDuration(BuildContext context, int ms) {
    final l10n = context.l10n;
    final minutes = ms ~/ 60000;
    if (minutes < 60) return l10n.durationMinutes(minutes);
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return l10n.durationHoursMinutes(hours, rem);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(shootingStatsProvider(_month));
    final l10n = context.l10n;

    return statsAsync.when(
      loading: () => OneUiSubpageScaffold(
        title: l10n.discoverShootingStats,
        isLoading: true,
        body: const SizedBox.shrink(),
      ),
      error: (e, _) => OneUiSubpageScaffold(
        title: l10n.discoverShootingStats,
        error: e,
        body: const SizedBox.shrink(),
      ),
      data: (stats) => OneUiSubpageScaffold(
        title: l10n.discoverShootingStats,
        subtitle: l10n.shootingStatsSubtitle,
        padding: const EdgeInsets.all(16),
        body: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month - 1);
                  }),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _month = DateTime(_month.year, _month.month + 1);
                  }),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatTile(l10n.shootingStatsPhotos, '${stats.photoCount}'),
            _StatTile(l10n.shootingStatsVideos, '${stats.videoCount}'),
            _StatTile(l10n.shootingStatsScreenshots, '${stats.screenshotCount}'),
            _StatTile(l10n.shootingStatsLiked, '${stats.likedCount}'),
            _StatTile(l10n.shootingStatsFolders, '${stats.folderCount}'),
            _StatTile(
              l10n.shootingStatsVideoDuration,
              _formatDuration(context, stats.totalVideoDurationMs),
            ),
            if (stats.mostActiveDay != null)
              _StatTile(
                l10n.shootingStatsMostActiveDay,
                l10n.shootingStatsMostActiveDayValue(
                  stats.mostActiveDay!,
                  stats.mostActiveDayCount,
                ),
              ),
            const SizedBox(height: 24),
            Text(
              l10n.shootingStatsHeatmap,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _Heatmap(counts: stats.dailyCounts),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (counts.isEmpty) {
      return Text(l10n.shootingStatsNoActivity);
    }
    final max = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: entries.map((e) {
        final intensity = max == 0 ? 0.0 : e.value / max;
        return Tooltip(
          message: l10n.shootingStatsHeatmapTooltip(e.key, e.value),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(
                alpha: 0.15 + intensity * 0.85,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              e.key.split('-').last,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        );
      }).toList(),
    );
  }
}
