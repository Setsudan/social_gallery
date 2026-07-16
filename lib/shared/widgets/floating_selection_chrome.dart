import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';
import 'package:social_gallery/shared/widgets/floating_bottom_nav.dart';
import 'package:social_gallery/shared/widgets/motion/pressable_scale.dart';

/// Frosted capsule used by selection chrome (matches shell bottom nav).
class FrostedPillShell extends StatelessWidget {
  const FrostedPillShell({
    super.key,
    required this.child,
    this.height,
    this.padding,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extent = height ?? kFloatingNavBarExtent;
    final radius = BorderRadius.circular(extent / 2);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.65),
            borderRadius: radius,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: SizedBox(
            height: extent,
            child: Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: OneUiSpacing.md),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingSelectionCountPill extends StatelessWidget {
  const FloatingSelectionCountPill({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return FrostedPillShell(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.md),
      child: Center(
        child: Text(
          l10n.selectionCount(count),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class FloatingSelectionCancelButton extends StatelessWidget {
  const FloatingSelectionCancelButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return FrostedPillShell(
      height: 40,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          tooltip: l10n.tooltipCancelSelection,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          icon: Icon(
            Icons.close,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class FloatingSelectionActionBar extends StatelessWidget {
  const FloatingSelectionActionBar({
    super.key,
    required this.onMove,
    required this.onShare,
    required this.onDelete,
    required this.onMore,
  });

  final VoidCallback onMove;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          OneUiSpacing.pageHorizontal,
          0,
          OneUiSpacing.pageHorizontal,
          kFloatingNavOuterBottomMargin +
              MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: FrostedPillShell(
          padding: const EdgeInsets.symmetric(horizontal: OneUiSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SelectionActionButton(
                icon: Icons.drive_file_move_outlined,
                label: l10n.selectionActionMove,
                onPressed: onMove,
              ),
              _SelectionActionButton(
                icon: Icons.share_outlined,
                label: l10n.selectionActionShare,
                onPressed: onShare,
              ),
              _SelectionActionButton(
                icon: Icons.delete_outline,
                label: l10n.selectionActionDelete,
                onPressed: onDelete,
              ),
              _SelectionActionButton(
                icon: Icons.more_horiz,
                label: l10n.selectionActionMore,
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurface;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      fontSize: 9,
      height: 1.0,
      fontWeight: FontWeight.w500,
      color: color,
    );

    return PressableScale(
      scale: 0.9,
      onTap: onPressed,
      child: SizedBox(
        width: 72,
        height: kFloatingNavBarExtent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}

enum SelectionMoreAction {
  favorite,
  unfavorite,
  createAlbum,
  copyToClipboard,
  setAsWallpaper,
}

Future<SelectionMoreAction?> showSelectionMoreSheet({
  required BuildContext context,
  required bool showCopy,
  required bool showWallpaper,
}) {
  final l10n = context.l10n;

  return showModalBottomSheet<SelectionMoreAction>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(l10n.tooltipFavoriteSelected),
              onTap: () =>
                  Navigator.pop(context, SelectionMoreAction.favorite),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: Text(l10n.tooltipUnfavoriteSelected),
              onTap: () =>
                  Navigator.pop(context, SelectionMoreAction.unfavorite),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: Text(l10n.tooltipCreateAlbumAndMove),
              onTap: () =>
                  Navigator.pop(context, SelectionMoreAction.createAlbum),
            ),
            if (showCopy)
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: Text(l10n.selectionCopyToClipboard),
                onTap: () => Navigator.pop(
                  context,
                  SelectionMoreAction.copyToClipboard,
                ),
              ),
            if (showWallpaper)
              ListTile(
                leading: const Icon(Icons.wallpaper_outlined),
                title: Text(l10n.selectionSetAsWallpaper),
                onTap: () => Navigator.pop(
                  context,
                  SelectionMoreAction.setAsWallpaper,
                ),
              ),
            const SizedBox(height: OneUiSpacing.sm),
          ],
        ),
      );
    },
  );
}
