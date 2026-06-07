import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class CompressionScreen extends ConsumerStatefulWidget {
  const CompressionScreen({super.key});

  @override
  ConsumerState<CompressionScreen> createState() => _CompressionScreenState();
}

class _CompressionScreenState extends ConsumerState<CompressionScreen> {
  static const thresholdBytes = 3 * 1024 * 1024;
  bool _loading = true;
  bool _compressing = false;
  List<MediaItem> _candidates = [];
  final _selected = <int>{};
  String? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ref.read(mediaRepositoryProvider).getAllHomeFeedMedia();
    setState(() {
      _candidates = items
          .where((i) => !i.isVideo && i.size >= thresholdBytes)
          .toList()
        ..sort((a, b) => b.size.compareTo(a.size));
      _loading = false;
    });
  }

  Future<String?> _resolvePath(MediaItem item) async {
    if (Platform.isWindows) return item.uri;
    final entity = await AssetEntity.fromId(item.uri);
    final file = await entity?.file;
    return file?.path;
  }

  Future<void> _compressSelected() async {
    if (_selected.isEmpty) return;
    setState(() {
      _compressing = true;
      _result = null;
    });

    var saved = 0;
    var done = 0;

    for (final id in _selected) {
      final item = _candidates.firstWhere((i) => i.id == id);
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
      _result = 'Compressed $done images, saved ${(saved / (1024 * 1024)).toStringAsFixed(1)} MB';
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final mobileOnly = kIsWeb || !(Platform.isAndroid || Platform.isIOS);

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
                  title: 'Image compression',
                  subtitle: 'Compress large photos without leaving the device.',
                ),
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
                Text('${_candidates.length} images over 3 MB'),
                const SizedBox(height: 8),
                ..._candidates.take(50).map((item) {
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
                      : _compressSelected,
                  child: Text(
                    _compressing
                        ? 'Compressing...'
                        : 'Compress ${_selected.length} selected',
                  ),
                ),
              ],
            ),
    );
  }
}
