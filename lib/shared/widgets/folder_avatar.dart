import 'dart:io';

import 'package:flutter/material.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class FolderAvatar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (locked) {
      return _lockAvatar(context);
    }

    final cover = coverUri?.trim();
    if (cover != null && cover.isNotEmpty) {
      final file = File(cover);
      if (file.existsSync()) {
        return ClipOval(
          child: SizedBox(
            width: size,
            height: size,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialAvatar(context),
            ),
          ),
        );
      }

      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: MediaThumbnail(assetId: cover),
        ),
      );
    }

    return _initialAvatar(context);
  }

  Widget _lockAvatar(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.lock,
        size: size * 0.45,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _initialAvatar(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        initial,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
