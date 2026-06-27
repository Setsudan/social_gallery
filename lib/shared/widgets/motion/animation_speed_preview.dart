import 'package:flutter/material.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/theme/one_ui_theme.dart';

/// Horizontal A-to-B motion preview for animation speed settings.
class AnimationSpeedPreview extends StatefulWidget {
  const AnimationSpeedPreview({super.key, required this.speedFactor});

  final double speedFactor;

  @override
  State<AnimationSpeedPreview> createState() => _AnimationSpeedPreviewState();
}

class _AnimationSpeedPreviewState extends State<AnimationSpeedPreview>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _position;

  static const double _height = 72;
  static const double _endpointSize = 8;
  static const double _circleSize = 20;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wasInitialized = _controller != null;
    _ensureController();
    if (!wasInitialized) {
      _syncAnimation(restart: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimationSpeedPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speedFactor != widget.speedFactor) {
      _syncAnimation(restart: true);
    }
  }

  @override
  void dispose() {
    _controller?.removeStatusListener(_onAnimationStatus);
    _controller?.dispose();
    super.dispose();
  }

  void _ensureController() {
    if (_controller != null) return;

    final motion = _motion();
    _controller = AnimationController(
      vsync: this,
      duration: motion.transition,
    )..addStatusListener(_onAnimationStatus);
    _position = CurvedAnimation(
      parent: _controller!,
      curve: motion.enterCurve,
    );
  }

  AppMotion _motion() {
    return AppMotion(
      speedFactor: widget.speedFactor,
      systemAnimationsDisabled: MediaQuery.disableAnimationsOf(context),
    );
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;

    final motion = _motion();
    if (!motion.enabled || motion.transition == Duration.zero) return;

    _controller?.forward(from: 0);
  }

  void _syncAnimation({required bool restart}) {
    _ensureController();
    final controller = _controller!;
    final motion = _motion();
    final duration = motion.transition;

    if (!motion.enabled || duration == Duration.zero) {
      controller.stop();
      controller.value = 1.0;
      if (mounted) setState(() {});
      return;
    }

    if (controller.duration != duration) {
      controller.duration = duration;
    }

    if (restart) {
      controller.forward(from: 0);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = _motion();
    final animation = _position ?? kAlwaysCompleteAnimation;

    return SizedBox(
      height: _height,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OneUiSpacing.lg,
            vertical: OneUiSpacing.md,
          ),
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final progress = motion.enabled ? (_position?.value ?? 0) : 1.0;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth - _circleSize;
                  final circleLeft = progress * trackWidth;
                  final trackTop = (constraints.maxHeight - 2) / 2;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: _endpointSize / 2,
                        right: _endpointSize / 2,
                        top: trackTop,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.55,
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: trackTop - (_endpointSize - 2) / 2,
                        child: _EndpointDot(theme: theme),
                      ),
                      Positioned(
                        right: 0,
                        top: trackTop - (_endpointSize - 2) / 2,
                        child: _EndpointDot(theme: theme),
                      ),
                      Positioned(
                        left: circleLeft,
                        top: (constraints.maxHeight - _circleSize) / 2,
                        child: Container(
                          width: _circleSize,
                          height: _circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EndpointDot extends StatelessWidget {
  const _EndpointDot({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _AnimationSpeedPreviewState._endpointSize,
      height: _AnimationSpeedPreviewState._endpointSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    );
  }
}
