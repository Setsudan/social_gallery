import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';

/// Session-scoped registry so scroll recycling does not replay entrances.
final staggeredEntranceRegistry = <Object>{};

/// Fade + slight slide for list/grid first paint (capped for performance).
class StaggeredEntrance extends ConsumerStatefulWidget {
  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.slideOffset = const Offset(0, 0.06),
    this.playOnceKey,
  });

  final int index;
  final Widget child;
  final Offset slideOffset;

  /// Stable id (e.g. media id). When set, the entrance runs at most once per session.
  final Object? playOnceKey;

  @override
  ConsumerState<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends ConsumerState<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 0);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _scheduleStart();
  }

  void _scheduleStart() {
    final motion = AppMotion.of(context, ref);
    final playKey = widget.playOnceKey;
    if (playKey != null && staggeredEntranceRegistry.contains(playKey)) {
      _controller.value = 1;
      return;
    }
    if (!motion.enabled || widget.index >= AppMotion.maxStaggerItems) {
      _controller.value = 1;
      if (playKey != null) staggeredEntranceRegistry.add(playKey);
      return;
    }
    _controller.duration = motion.fade;
    final delay = motion.staggerStep * widget.index;
    Future<void>.delayed(delay, () {
      if (!mounted) return;
      _controller.forward().whenComplete(() {
        if (playKey != null) staggeredEntranceRegistry.add(playKey);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context, ref);
    if (!motion.enabled || widget.index >= AppMotion.maxStaggerItems) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
