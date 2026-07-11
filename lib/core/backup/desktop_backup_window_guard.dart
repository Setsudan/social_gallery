import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:window_manager/window_manager.dart';

/// Prompts before closing the desktop window during an active mobile backup.
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

  Future<bool> _showCloseConfirmDialog() async {
    if (!mounted || _dialogVisible) return false;
    _dialogVisible = true;
    final l10n = context.l10n;
    final backupState = ref.read(desktopBackupProvider);
    var message = l10n.backupCloseBlockedMessage;
    final fileName = backupState.receivingFileName;
    if (fileName != null && fileName.isNotEmpty) {
      final total = backupState.receivingBytesTotal;
      if (total > 0) {
        final percent =
            ((backupState.receivingBytesReceived / total) * 100).round();
        message = '$message\n\n$fileName ($percent%)';
      } else {
        message = '$message\n\n$fileName';
      }
    }

    final quitAnyway = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.backupCloseBlockedTitle),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.backupCloseWait),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.backupCloseQuitAnyway),
            ),
          ],
        );
      },
    );
    _dialogVisible = false;
    return quitAnyway ?? false;
  }

  Future<void> _handleWindowClose() async {
    final isReceiving = ref.read(
      desktopBackupProvider.select((state) => state.isReceivingBackup),
    );
    if (!isReceiving) {
      await windowManager.destroy();
      return;
    }

    final quitAnyway = await _showCloseConfirmDialog();
    if (!quitAnyway || !mounted) return;

    await ref.read(desktopBackupProvider.notifier).shutdownForWindowClose();
    await windowManager.destroy();
  }

  @override
  void onWindowClose() {
    unawaited(_handleWindowClose());
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
