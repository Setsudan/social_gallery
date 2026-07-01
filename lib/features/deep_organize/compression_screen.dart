import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/features/discover/discover_providers.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_subpage_scaffold.dart';

class CompressionScreen extends ConsumerStatefulWidget {
  const CompressionScreen({super.key});

  @override
  ConsumerState<CompressionScreen> createState() => _CompressionScreenState();
}

class _CompressionScreenState extends ConsumerState<CompressionScreen> {
  bool _compressing = false;
  final _selected = <int>{};
  String? _result;

  Future<String?> _resolvePath(MediaItem item) async {
    if (usesFilesystemGallery) return item.uri;
    final entity = await AssetEntity.fromId(item.uri);
    final file = await entity?.file;
    return file?.path;
  }

  Future<void> _compressSelected(List<MediaItem> candidates) async {
    if (_selected.isEmpty) return;
    setState(() {
      _compressing = true;
      _result = null;
    });

    var saved = 0;
    var done = 0;

    for (final id in _selected) {
      final item = candidates.firstWhere((i) => i.id == id);
      final path = await _resolvePath(item);
      if (path == null) continue;

      try {
        final tempDir = await getTemporaryDirectory();
        final outPath =
            '${tempDir.path}/compressed_${item.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final out = await FlutterImageCompress.compressAndGetFile(
          path,
          outPath,
          quality: 75,
          keepExif: true,
        );
        if (out != null) {
          final newSize = await out.length();
          saved += item.size - newSize;
          done++;
          await File(path).writeAsBytes(await out.readAsBytes());
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _compressing = false;
      _result = context.l10n.compressionResult(
        done,
        (saved / (1024 * 1024)).round(),
      );
      _selected.clear();
    });
    ref.invalidate(compressionCandidatesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final mobileOnly = kIsWeb || !(Platform.isAndroid || Platform.isIOS);
    final candidatesAsync = ref.watch(compressionCandidatesProvider);
    final l10n = context.l10n;

    return candidatesAsync.when(
      loading: () => OneUiSubpageScaffold(
        title: l10n.compressionTitle,
        isLoading: true,
        body: const SizedBox.shrink(),
      ),
      error: (e, _) => OneUiSubpageScaffold(
        title: l10n.compressionTitle,
        error: e,
        body: const SizedBox.shrink(),
      ),
      data: (candidates) => OneUiSubpageScaffold(
        title: l10n.compressionTitle,
        subtitle: l10n.compressionSubtitle,
        padding: const EdgeInsets.all(16),
        body: ListView(
          children: [
            if (mobileOnly)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.compressionBestOnMobile),
                  subtitle: Text(l10n.compressionBestOnMobileSubtitle),
                ),
              ),
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(_result!),
            ],
            const SizedBox(height: 16),
            Text(l10n.compressionCandidatesCount(candidates.length)),
            const SizedBox(height: 8),
            ...candidates.take(50).map((item) {
              final selected = _selected.contains(item.id);
              return CheckboxListTile(
                value: selected,
                onChanged: _compressing
                    ? null
                    : (v) {
                        setState(() {
                          if (v == true) {
                            _selected.add(item.id);
                          } else {
                            _selected.remove(item.id);
                          }
                        });
                      },
                title: Text(item.displayName, maxLines: 1),
                subtitle: Text(
                  '${(item.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _compressing || _selected.isEmpty
                  ? null
                  : () => _compressSelected(candidates),
              child: Text(
                _compressing
                    ? l10n.compressionCompressing
                    : l10n.compressionCompressSelected(_selected.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
