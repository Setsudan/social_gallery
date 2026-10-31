import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:video_player/video_player.dart';

/// Lists locally inventoried cloud-backed items; decrypts on open.
class CloudArchiveScreen extends ConsumerStatefulWidget {
  const CloudArchiveScreen({super.key});

  @override
  ConsumerState<CloudArchiveScreen> createState() => _CloudArchiveScreenState();
}

class _CloudArchiveScreenState extends ConsumerState<CloudArchiveScreen> {
  var _loading = true;
  List<MediaItem> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ref
        .read(mediaRepositoryProvider)
        .getCloudBackedUpMedia(limit: 500);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _open(MediaItem item) async {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file = await ref
          .read(cloudBackupProvider.notifier)
          .downloadAndDecrypt(item);
      if (!mounted) return;
      Navigator.pop(context);
      if (file == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.cloudArchiveDecryptFailed)));
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _CloudArchiveViewer(item: item, file: file),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.cloudArchiveDecryptFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.cloudArchiveBrowseTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(child: Text(l10n.cloudArchiveEmpty))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Icon(
                    item.isVideo
                        ? Icons.videocam_outlined
                        : Icons.image_outlined,
                  ),
                  title: Text(item.displayName),
                  subtitle: Text(item.folderName),
                  onTap: () => _open(item),
                );
              },
            ),
    );
  }
}

class _CloudArchiveViewer extends StatefulWidget {
  const _CloudArchiveViewer({required this.item, required this.file});

  final MediaItem item;
  final File file;

  @override
  State<_CloudArchiveViewer> createState() => _CloudArchiveViewerState();
}

class _CloudArchiveViewerState extends State<_CloudArchiveViewer> {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    if (widget.item.isVideo) {
      _video = VideoPlayerController.file(widget.file)
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _video?.play();
        });
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    try {
      widget.file.parent.deleteSync(recursive: true);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.displayName)),
      backgroundColor: Colors.black,
      body: Center(
        child: widget.item.isVideo
            ? (_video != null && _video!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _video!.value.aspectRatio,
                      child: VideoPlayer(_video!),
                    )
                  : const CircularProgressIndicator())
            : InteractiveViewer(
                child: Image.file(widget.file, fit: BoxFit.contain),
              ),
      ),
    );
  }
}
