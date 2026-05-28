import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/modal_sheet.dart';
import 'package:social_gallery/core/auth/folder_access.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';

/// Folder list with local search; biometric gate for locked folders on select.
Future<String?> showFolderPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<FolderInfo> folders,
  String title = 'Move items to...',
  Iterable<String> excludePaths = const [],
}) {
  final excluded = excludePaths.toSet();
  final choices = folders.where((f) => !excluded.contains(f.path)).toList();

  return showAppModalBottomSheet<String>(
    context: context,
    ref: ref,
    builder: (sheetContext) {
      return _FolderPickerSheetBody(title: title, folders: choices);
    },
  );
}

class _FolderPickerSheetBody extends ConsumerStatefulWidget {
  const _FolderPickerSheetBody({required this.title, required this.folders});

  final String title;
  final List<FolderInfo> folders;

  @override
  ConsumerState<_FolderPickerSheetBody> createState() =>
      _FolderPickerSheetBodyState();
}

class _FolderPickerSheetBodyState
    extends ConsumerState<_FolderPickerSheetBody> {
  final _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  List<FolderInfo> get _filtered {
    final query = _queryController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.folders;
    return widget.folders
        .where((f) => f.name.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _selectFolder(FolderInfo folder) async {
    final ok = await ensureFolderUnlocked(ref: ref, folder: folder);
    if (!ok || !mounted) return;
    Navigator.pop(context, folder.path);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
            ),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              OneUiSpacing.pageHorizontal,
              0,
              OneUiSpacing.pageHorizontal,
              OneUiSpacing.sm,
            ),
            child: SearchBar(
              controller: _queryController,
              hintText: 'Search folders',
              leading: const Icon(Icons.search, size: 20),
              onChanged: (_) => setState(() {}),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final folder = filtered[index];
                return ListTile(
                  leading: FolderAvatar(
                    name: folder.name,
                    coverUri: folder.isLockedAccount
                        ? null
                        : folder.coverImageUri,
                    locked: folder.isLockedAccount,
                  ),
                  title: Text(folder.name),
                  subtitle: Text('${folder.mediaCount} items'),
                  onTap: () => _selectFolder(folder),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
