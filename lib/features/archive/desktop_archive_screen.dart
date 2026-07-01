import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/backup/backup_protocol.dart';
import 'package:social_gallery/core/backup/desktop_library_controller.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/features/settings/vault_password_dialog.dart';
import 'package:video_player/video_player.dart';

class DesktopArchiveScreen extends ConsumerStatefulWidget {
  const DesktopArchiveScreen({super.key});

  @override
  ConsumerState<DesktopArchiveScreen> createState() =>
      _DesktopArchiveScreenState();
}

class _DesktopArchiveScreenState extends ConsumerState<DesktopArchiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(desktopLibraryProvider.notifier).loadCatalog();
    });
  }

  Future<void> _openFolder(LibraryCatalogFolder folder) async {
    if (folder.isVault && !ref.read(desktopLibraryProvider).vaultUnlocked) {
      final password = await showVaultPasswordDialog(
        context,
        isNewPassword: false,
      );
      if (password == null || !mounted) return;
      final unlocked = await ref
          .read(desktopLibraryProvider.notifier)
          .unlockVault(password: password);
      if (!unlocked || !mounted) return;
    }

    await ref
        .read(desktopLibraryProvider.notifier)
        .loadCatalog(folderName: folder.folderName);
  }

  Future<void> _openItem(LibraryCatalogItem item) async {
    if (item.isVault && !ref.read(desktopLibraryProvider).vaultUnlocked) {
      final password = await showVaultPasswordDialog(
        context,
        isNewPassword: false,
      );
      if (password == null || !mounted) return;
      final unlocked = await ref
          .read(desktopLibraryProvider.notifier)
          .unlockVault(password: password);
      if (!unlocked || !mounted) return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _DesktopArchiveViewerScreen(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(desktopLibraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.desktopArchiveTitle),
        leading: state.selectedFolder == null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(desktopLibraryProvider.notifier).loadCatalog();
                },
              ),
      ),
      body: switch (state.phase) {
        DesktopLibraryPhase.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        DesktopLibraryPhase.error => Center(
          child: Text(state.error ?? l10n.desktopArchiveLoadFailed),
        ),
        DesktopLibraryPhase.ready when state.selectedFolder == null =>
          _FolderList(
            folders: state.folders,
            onTap: _openFolder,
          ),
        DesktopLibraryPhase.ready => _ItemGrid(
          items: state.items,
          onTap: _openItem,
          loadThumbnail: (item) =>
              ref.read(desktopLibraryProvider.notifier).loadThumbnail(item),
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _FolderList extends StatelessWidget {
  const _FolderList({
    required this.folders,
    required this.onTap,
  });

  final List<LibraryCatalogFolder> folders;
  final Future<void> Function(LibraryCatalogFolder folder) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (folders.isEmpty) {
      return Center(child: Text(l10n.desktopArchiveEmpty));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(OneUiSpacing.pageHorizontal),
      itemCount: folders.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: OneUiSpacing.sm),
      itemBuilder: (context, index) {
        final folder = folders[index];
        return ListTile(
          leading: Icon(
            folder.isVault ? Icons.lock : Icons.folder,
          ),
          title: Text(folder.folderName),
          subtitle: Text(l10n.desktopArchiveItemCount(folder.itemCount)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onTap(folder),
        );
      },
    );
  }
}

class _ItemGrid extends StatelessWidget {
  const _ItemGrid({
    required this.items,
    required this.onTap,
    required this.loadThumbnail,
  });

  final List<LibraryCatalogItem> items;
  final Future<void> Function(LibraryCatalogItem item) onTap;
  final Future<Uint8List?> Function(LibraryCatalogItem item) loadThumbnail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (items.isEmpty) {
      return Center(child: Text(l10n.desktopArchiveEmpty));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(OneUiSpacing.pageHorizontal),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isVideo = item.mime.startsWith('video/');

        return GestureDetector(
          onTap: () => onTap(item),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List?>(
                future: isVideo ? Future.value(null) : loadThumbnail(item),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  }
                  return ColoredBox(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(isVideo ? Icons.videocam : Icons.image),
                  );
                },
              ),
              if (item.isVault)
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Icon(Icons.lock, size: 16, color: Colors.white),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopArchiveViewerScreen extends ConsumerStatefulWidget {
  const _DesktopArchiveViewerScreen({required this.item});

  final LibraryCatalogItem item;

  @override
  ConsumerState<_DesktopArchiveViewerScreen> createState() =>
      _DesktopArchiveViewerScreenState();
}

class _DesktopArchiveViewerScreenState
    extends ConsumerState<_DesktopArchiveViewerScreen> {
  VideoPlayerController? _videoController;
  Uint8List? _imageBytes;
  File? _tempFile;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final controller = ref.read(desktopLibraryProvider.notifier);
    final stream = await controller.initStream(widget.item);
    final client = controller.client;

    if (stream == null || client == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Stream failed';
      });
      return;
    }

    if (widget.item.mime.startsWith('video/')) {
      final file = await client.downloadToTempFile(
        sessionId: stream.sessionId,
        totalSize: stream.size,
      );
      if (file == null || !mounted) {
        setState(() {
          _loading = false;
          _error = 'Stream failed';
        });
        return;
      }

      _tempFile = file;
      _videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _loading = false);
            _videoController!.play();
          }
        });
      return;
    }

    final bytes = await client.downloadToTempFile(
      sessionId: stream.sessionId,
      totalSize: stream.size,
    );
    if (bytes == null || !mounted) {
      setState(() {
        _loading = false;
        _error = 'Stream failed';
      });
      return;
    }

    final data = await bytes.readAsBytes();
    setState(() {
      _imageBytes = data;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _tempFile?.deleteSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.item.fileName),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Text(_error!, style: const TextStyle(color: Colors.white))
                : _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : _imageBytes != null
                        ? InteractiveViewer(
                            child: Image.memory(_imageBytes!),
                          )
                        : Text(
                            l10n.desktopArchiveStreamFailed,
                            style: const TextStyle(color: Colors.white),
                          ),
      ),
    );
  }
}
