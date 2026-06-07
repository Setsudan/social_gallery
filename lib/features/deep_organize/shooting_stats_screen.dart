import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class ShootingStatsScreen extends ConsumerStatefulWidget {
  const ShootingStatsScreen({super.key});

  @override
  ConsumerState<ShootingStatsScreen> createState() =>
      _ShootingStatsScreenState();
}

class _ShootingStatsScreenState extends ConsumerState<ShootingStatsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _loading = true;
  ShootingStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ref.read(mediaRepositoryProvider).getAllHomeFeedMedia();
    final stats = ref.read(computeShootingStatsProvider)(
      items: items,
      month: _month,
    );
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
    _load();
  }

  String _formatDuration(int ms) {
    final minutes = ms ~/ 60000;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return '${hours}h ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const OneUiPageHeader(
                  title: 'Shooting stats',
                  subtitle: 'Your on-device photography habits.',
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _StatTile('Photos', '${_stats?.photoCount ?? 0}'),
                _StatTile('Videos', '${_stats?.videoCount ?? 0}'),
                _StatTile('Screenshots', '${_stats?.screenshotCount ?? 0}'),
                _StatTile('Liked', '${_stats?.likedCount ?? 0}'),
                _StatTile('Folders', '${_stats?.folderCount ?? 0}'),
                _StatTile(
                  'Video duration',
                  _formatDuration(_stats?.totalVideoDurationMs ?? 0),
                ),
                if (_stats?.mostActiveDay != null)
                  _StatTile(
                    'Most active day',
                    '${_stats!.mostActiveDay} (${_stats!.mostActiveDayCount})',
                  ),
                const SizedBox(height: 24),
                Text(
                  'Activity heatmap',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _Heatmap(counts: _stats?.dailyCounts ?? {}),
              ],
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
    if (counts.isEmpty) {
      return const Text('No activity this month.');
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
          message: '${e.key}: ${e.value}',
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
