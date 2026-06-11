import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';

/// Tap feedback: brief scale-down while pressed.
class PressableScale extends ConsumerStatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.scale = 0.96,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool enabled;

  @override
  ConsumerState<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends ConsumerState<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context, ref);
    final targetScale = _pressed && motion.enabled ? widget.scale : 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled && widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.enabled && widget.onTap != null
          ? (_) => setState(() => _pressed = false)
          : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTap: widget.enabled ? widget.onTap : null,
      onDoubleTap: widget.enabled ? widget.onDoubleTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      child: AnimatedScale(
        scale: targetScale,
        duration: motion.fadeFast,
        curve: motion.enterCurve,
        child: widget.child,
      ),
    );
  }
}
