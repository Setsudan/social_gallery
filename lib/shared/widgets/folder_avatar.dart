import 'dart:io';

import 'package:flutter/material.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class FolderAvatar extends StatefulWidget {
  const FolderAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.coverUri,
    this.locked = false,
  });

  final String name;
  final double size;
  final String? coverUri;
  final bool locked;

  @override
  State<FolderAvatar> createState() => _FolderAvatarState();
}

class _FolderAvatarState extends State<FolderAvatar> {
  String? _resolvedUri;
  bool? _fileExists;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveCover();
  }

  @override
  void didUpdateWidget(FolderAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coverUri != widget.coverUri ||
        oldWidget.locked != widget.locked) {
      _resolveCover();
    }
  }

  void _resolveCover() {
    if (widget.locked) {
      _resolvedUri = null;
      _fileExists = null;
      return;
    }

    final cover = widget.coverUri?.trim();
    if (cover == null || cover.isEmpty) {
      _resolvedUri = null;
      _fileExists = null;
      return;
    }

    if (_resolvedUri == cover && _fileExists != null) return;

    _resolvedUri = cover;
    final path = cover.startsWith('file://')
        ? Uri.parse(cover).toFilePath()
        : cover;
    final looksLikeFilePath =
        path.startsWith('/') || (path.length > 2 && path[1] == ':');
    if (looksLikeFilePath) {
      _fileExists = File(path).existsSync();
    } else {
      _fileExists = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(child: _buildAvatar(context));
  }

  Widget _buildAvatar(BuildContext context) {
    if (widget.locked) {
      return _lockAvatar(context);
    }

    final cover = _resolvedUri;
    if (cover != null && cover.isNotEmpty) {
      if (_fileExists == true) {
        final path = cover.startsWith('file://')
            ? Uri.parse(cover).toFilePath()
            : cover;
        return ClipOval(
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              cacheWidth: (widget.size *
                      MediaQuery.devicePixelRatioOf(context))
                  .ceil()
                  .clamp(48, 256),
              errorBuilder: (context, error, stackTrace) =>
                  _initialAvatar(context),
            ),
          ),
        );
      }

      return ClipOval(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: MediaThumbnail(
            assetId: cover,
            maxThumbnailEdge: (widget.size *
                    MediaQuery.devicePixelRatioOf(context))
                .ceil()
                .clamp(48, 128),
          ),
        ),
      );
    }

    return _initialAvatar(context);
  }

  Widget _lockAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.lock,
        size: widget.size * 0.45,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _initialAvatar(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: widget.size * 0.38,
        ),
      ),
    );
  }
}
