import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
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

    setState(() {
      _compressing = false;
      _result =
          'Compressed $done images, saved ${(saved / (1024 * 1024)).toStringAsFixed(1)} MB';
      _selected.clear();
    });
    ref.invalidate(compressionCandidatesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final mobileOnly = kIsWeb || !(Platform.isAndroid || Platform.isIOS);
    final candidatesAsync = ref.watch(compressionCandidatesProvider);

    return candidatesAsync.when(
      loading: () => OneUiSubpageScaffold(
        title: 'Image compression',
        isLoading: true,
        body: const SizedBox.shrink(),
      ),
      error: (e, _) => OneUiSubpageScaffold(
        title: 'Image compression',
        error: e,
        body: const SizedBox.shrink(),
      ),
      data: (candidates) => OneUiSubpageScaffold(
        title: 'Image compression',
        subtitle: 'Compress large photos without leaving the device.',
        padding: const EdgeInsets.all(16),
        body: ListView(
          children: [
            if (mobileOnly)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Best on mobile'),
                  subtitle: Text(
                    'Compression works on Android and iOS. Desktop support is limited.',
                  ),
                ),
              ),
            if (_result != null) ...[
              const SizedBox(height: 8),
              Text(_result!),
            ],
            const SizedBox(height: 16),
            Text('${candidates.length} images over 3 MB'),
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
                    ? 'Compressing...'
                    : 'Compress ${_selected.length} selected',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
