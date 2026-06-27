import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/organize_models.dart';

class OrganizeFilterSheet extends ConsumerStatefulWidget {
  const OrganizeFilterSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final OrganizeFilter initial;
  final ValueChanged<OrganizeFilter> onApply;

  static Future<void> show(
    BuildContext context, {
    required OrganizeFilter initial,
    required ValueChanged<OrganizeFilter> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          OrganizeFilterSheet(initial: initial, onApply: onApply),
    );
  }

  @override
  ConsumerState<OrganizeFilterSheet> createState() =>
      _OrganizeFilterSheetState();
}

class _OrganizeFilterSheetState extends ConsumerState<OrganizeFilterSheet> {
  late OrganizeMediaType _type;
  String? _folderPath;
  String? _month;

  @override
  void initState() {
    super.initState();
    _type = widget.initial.mediaType;
    _folderPath = widget.initial.folderPath;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(allFoldersProvider).valueOrNull ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Media type', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<OrganizeMediaType>(
              segments: const [
                ButtonSegment(
                  value: OrganizeMediaType.all,
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: OrganizeMediaType.image,
                  label: Text('Image'),
                ),
                ButtonSegment(
                  value: OrganizeMediaType.video,
                  label: Text('Video'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                setState(() => _type = set.first);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _folderPath,
              decoration: const InputDecoration(labelText: 'Folder'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All folders')),
                ...folders.map(
                  (f) => DropdownMenuItem(value: f.path, child: Text(f.name)),
                ),
              ],
              onChanged: (v) => setState(() => _folderPath = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _month,
              decoration: const InputDecoration(
                labelText: 'Month (YYYY-MM)',
                hintText: '2024-06',
              ),
              onChanged: (v) => _month = v.trim().isEmpty ? null : v.trim(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(const OrganizeFilter());
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(
                        OrganizeFilter(
                          folderPath: _folderPath,
                          mediaType: _type,
                          month: _month,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
