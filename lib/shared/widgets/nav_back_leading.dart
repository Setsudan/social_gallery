import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Explicit AppBar leading that pops via go_router when the stack can pop.
class NavBackLeading extends StatelessWidget {
  const NavBackLeading({
    super.key,
    this.onPressed,
    this.icon = Icons.arrow_back,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final canPop = onPressed != null ||
        GoRouter.of(context).canPop() ||
        Navigator.of(context).canPop();
    if (!canPop) return const SizedBox.shrink();

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed ??
          () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
    );
  }
}
