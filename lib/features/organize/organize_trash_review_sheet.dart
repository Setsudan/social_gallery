import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';

class OrganizeTrashReviewSheet extends StatefulWidget {
  const OrganizeTrashReviewSheet({
    super.key,
    required this.items,
    required this.onConfirm,
  });

  final List<MediaItem> items;
  final Future<void> Function(List<int> ids) onConfirm;

  static Future<void> show(
    BuildContext context, {
    required List<MediaItem> items,
    required Future<void> Function(List<int> ids) onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          OrganizeTrashReviewSheet(items: items, onConfirm: onConfirm),
    );
  }

  @override
  State<OrganizeTrashReviewSheet> createState() =>
      _OrganizeTrashReviewSheetState();
}

class _OrganizeTrashReviewSheetState extends State<OrganizeTrashReviewSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.items.map((e) => e.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.organizeTrashReviewTitle(widget.items.length),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.organizeTrashReviewMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  final selected = _selected.contains(item.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selected.remove(item.id);
                        } else {
                          _selected.add(item.id);
                        }
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: MediaThumbnail(
                            assetId: item.uri,
                            showVideoBadge: item.isVideo,
                          ),
                        ),
                        if (!selected)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close, color: Colors.white),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () async {
                      await widget.onConfirm(_selected.toList());
                      if (context.mounted) Navigator.pop(context);
                    },
              child: Text(l10n.organizeTrashDeleteCount(_selected.length)),
            ),
          ],
        ),
      ),
    );
  }
}
