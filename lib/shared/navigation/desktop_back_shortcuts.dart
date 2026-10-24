import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';

class _DesktopBackIntent extends Intent {
  const _DesktopBackIntent();
}

/// Escape (and browser-style Alt+Left) maps to navigator back on desktop.
///
/// Uses [Navigator.maybePop] so [PopScope] / [BackButtonListener] handlers
/// (selection cancel, search exit) still run when [PopScope.canPop] is false.
class DesktopBackShortcuts extends StatelessWidget {
  const DesktopBackShortcuts({super.key, required this.child});

  final Widget child;

  static void handleBack(BuildContext context) {
    final nav = Navigator.maybeOf(context);
    if (nav == null) return;
    unawaited(nav.maybePop());
  }

  @override
  Widget build(BuildContext context) {
    if (!usesFilesystemGallery) return child;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): _DesktopBackIntent(),
        SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
            _DesktopBackIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _DesktopBackIntent: CallbackAction<_DesktopBackIntent>(
            onInvoke: (_) {
              handleBack(context);
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
