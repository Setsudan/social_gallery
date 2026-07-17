import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:social_gallery/shared/navigation/shell_nav_config.dart';

/// Active bottom-shell branch index; updated by [MainShell] on tab change.
final activeShellTabProvider = StateProvider<int>((ref) => kShellTabHome);

/// Defers building [child] until its shell tab is first selected.
///
/// After the first visit the tab stays mounted (IndexedStack) without reloading
/// providers for inactive tabs on cold start.
class DeferredShellTab extends ConsumerStatefulWidget {
  const DeferredShellTab({
    super.key,
    required this.tabIndex,
    required this.child,
  });

  final int tabIndex;
  final Widget child;

  @override
  ConsumerState<DeferredShellTab> createState() => _DeferredShellTabState();
}

class _DeferredShellTabState extends ConsumerState<DeferredShellTab>
    with AutomaticKeepAliveClientMixin {
  bool _activated = false;

  @override
  bool get wantKeepAlive => _activated;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final active = ref.watch(activeShellTabProvider);
    if (active == widget.tabIndex) {
      _activated = true;
    }
    if (!_activated) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}
