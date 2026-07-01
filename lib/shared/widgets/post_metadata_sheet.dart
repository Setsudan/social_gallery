import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/domain/models/media_item.dart';

class PostMetadataSheet extends StatelessWidget {
  const PostMetadataSheet({super.key, required this.media, this.fileSizeLabel});

  final MediaItem media;
  final String? fileSizeLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final taken = media.dateTaken ?? media.dateModified;
    final takenLabel = _formatDate(taken);
    final addedLabel = _formatDate(media.dateAdded);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l10n.metadataTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _row(context, l10n.metadataFilename, media.displayName),
            if (media.width != null && media.height != null)
              _row(
                context,
                l10n.metadataDimensions,
                l10n.metadataDimensionsValue(media.width!, media.height!),
              ),
            _row(context, l10n.metadataType, media.mimeType),
            if (fileSizeLabel != null)
              _row(context, l10n.metadataSize, fileSizeLabel!),
            _row(context, l10n.metadataDateTaken, takenLabel),
            _row(context, l10n.metadataDateAdded, addedLabel),
            _row(context, l10n.metadataFolder, media.folderName),
          ],
        ),
      ),
    );
  }

  static String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
