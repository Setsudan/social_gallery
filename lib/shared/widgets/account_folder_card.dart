import 'package:flutter/material.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

class AccountFolderCard extends StatelessWidget {
  const AccountFolderCard({
    super.key,
    required this.folder,
    required this.onTap,
  });

  final FolderInfo folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderSide = BorderSide(color: theme.dividerColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: OneUiSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: borderSide)),
        child: PressableScale(
          onTap: onTap,
          child: ListTile(
            leading: FolderAvatar(
              name: folder.name,
              locked: true,
            ),
            title: Text(
              folder.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Locked folder - tap to unlock',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
