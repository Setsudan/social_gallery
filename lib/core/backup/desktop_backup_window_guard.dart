import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:window_manager/window_manager.dart';

/// Blocks window close while the desktop is actively receiving a mobile backup.
class DesktopBackupWindowGuard extends ConsumerStatefulWidget {
  const DesktopBackupWindowGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DesktopBackupWindowGuard> createState() =>
      _DesktopBackupWindowGuardState();
}

class _DesktopBackupWindowGuardState extends ConsumerState<DesktopBackupWindowGuard>
    with WindowListener {
  bool _dialogVisible = false;

  bool get _supportsWindowGuard =>
      usesFilesystemGallery &&
      !Platform.isAndroid &&
      !Platform.isIOS;

  @override
  void initState() {
    super.initState();
    if (_supportsWindowGuard) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    if (_supportsWindowGuard) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _syncPreventClose(bool isReceiving) async {
    if (!_supportsWindowGuard) return;
    await windowManager.setPreventClose(isReceiving);
  }

  Future<void> _showCloseBlockedDialog() async {
    if (!mounted || _dialogVisible) return;
    _dialogVisible = true;
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.backupCloseBlockedTitle),
          content: Text(l10n.backupCloseBlockedMessage),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.actionOk),
            ),
          ],
        );
      },
    );
    _dialogVisible = false;
  }

  @override
  void onWindowClose() {
    final isReceiving = ref.read(
      desktopBackupProvider.select((state) => state.isReceivingBackup),
    );
    if (isReceiving) {
      unawaited(_showCloseBlockedDialog());
      return;
    }
    unawaited(windowManager.destroy());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(
      desktopBackupProvider.select((state) => state.isReceivingBackup),
      (previous, next) {
        unawaited(_syncPreventClose(next));
      },
    );

    return widget.child;
  }
}
