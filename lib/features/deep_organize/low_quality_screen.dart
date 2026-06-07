import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class LowQualityScreen extends ConsumerStatefulWidget {
  const LowQualityScreen({super.key});

  @override
  ConsumerState<LowQualityScreen> createState() => _LowQualityScreenState();
}

class _LowQualityScreenState extends ConsumerState<LowQualityScreen> {
  bool _loading = true;
  List<({MediaItem item, List<String> reasons})> _queue = [];
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final mediaRepo = ref.read(mediaRepositoryProvider);
    final analysisRepo = ref.read(mediaAnalysisRepositoryProvider);
    final scoreLowQuality = ref.read(scoreLowQualityProvider);

    final items = await mediaRepo.getAllHomeFeedMedia();
    final analysis = await analysisRepo.getAllCached();
    final scored = scoreLowQuality(items: items, analysisById: analysis);
    final byId = {for (final i in items) i.id: i};

    setState(() {
      _queue = scored
          .where((s) => byId.containsKey(s.mediaId))
          .map((s) => (item: byId[s.mediaId]!, reasons: s.reasons))
          .toList();
      _index = 0;
      _loading = false;
    });
  }

  Future<void> _deleteCurrent() async {
    if (_index >= _queue.length) return;
    final item = _queue[_index].item;
    await ref.read(mediaRepositoryProvider).deleteFromDevice([item]);
    setState(() {
      _queue.removeAt(_index);
      if (_index >= _queue.length && _index > 0) _index--;
    });
    ref.invalidate(discoverHubProvider);
  }

  void _skip() {
    if (_index < _queue.length - 1) {
      setState(() => _index++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: _queue.isEmpty
            ? null
            : Text('${_index + 1} / ${_queue.length}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _queue.isEmpty
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OneUiPageHeader(
                  title: 'Low quality',
                  subtitle: 'Run a scan from Deep organize first.',
                ),
                Expanded(child: Center(child: Text('No low-quality items.'))),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OneUiPageHeader(
                  title: 'Low quality review',
                  subtitle: 'Review flagged shots and delete what you do not need.',
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: MediaThumbnail(
                        assetId: _queue[_index].item.uri,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: _queue[_index].reasons
                        .map(
                          (r) => Chip(
                            label: Text(r),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _skip,
                          child: const Text('Keep'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _deleteCurrent,
                          child: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
