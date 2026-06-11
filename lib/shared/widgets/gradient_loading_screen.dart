import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class GradientLoadingScreen extends StatefulWidget {
  const GradientLoadingScreen({
    super.key,
    this.message,
    this.detail,
    this.progress,
    this.processed,
    this.total,
    this.error,
    this.onSkip,
    this.showIndicator = true,
  });

  final String? message;
  final String? detail;
  final double? progress;
  final int? processed;
  final int? total;
  final String? error;
  final VoidCallback? onSkip;
  final bool showIndicator;

  @override
  State<GradientLoadingScreen> createState() => _GradientLoadingScreenState();
}

class _GradientLoadingScreenState extends State<GradientLoadingScreen>
    with TickerProviderStateMixin {
  static const _beige = Color(0xFFF4EDE4);
  static const _beigeDeep = Color(0xFFE8DDD0);

  static const _orbs = [
    _OrbSpec(color: Color(0xFFFF8FAB), size: 220, phase: 0.0, speed: 1.0),
    _OrbSpec(color: Color(0xFF8EC5FC), size: 260, phase: 1.4, speed: 0.85),
    _OrbSpec(color: Color(0xFFFFD36E), size: 200, phase: 2.6, speed: 1.1),
    _OrbSpec(color: Color(0xFFB388FF), size: 240, phase: 3.8, speed: 0.75),
    _OrbSpec(color: Color(0xFF7BE495), size: 180, phase: 5.0, speed: 0.95),
  ];

  late final AnimationController _orbController;
  late final AnimationController _progressController;
  double _displayProgress = 0;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _displayProgress = widget.progress ?? 0;
    _progressController.value = _displayProgress.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant GradientLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animateProgress(oldWidget.progress, widget.progress);
  }

  void _animateProgress(double? previous, double? next) {
    if (next == null) return;
    final begin = _displayProgress;
    final end = next.clamp(0.0, 1.0);
    if ((end - begin).abs() < 0.001) return;

    _progressController.stop();
    final animation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    void listener() {
      if (!mounted) return;
      setState(() => _displayProgress = animation.value);
    }

    animation.addListener(listener);
    _progressController.forward(from: 0).whenComplete(() {
      animation.removeListener(listener);
      if (mounted) {
        setState(() => _displayProgress = end);
      }
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Offset _orbOffset(Size size, _OrbSpec orb, double t) {
    final w = size.width;
    final h = size.height;
    final angle = (t * orb.speed + orb.phase) * 2 * math.pi;
    final driftX = math.sin(angle) * w * 0.22 + math.cos(angle * 0.6) * w * 0.08;
    final driftY =
        math.cos(angle * 0.85) * h * 0.18 + math.sin(angle * 0.45) * h * 0.1;

    return Offset(
      w * 0.5 + driftX - orb.size * 0.5,
      h * 0.42 + driftY - orb.size * 0.5,
    );
  }

  String? get _countLabel {
    final processed = widget.processed;
    final total = widget.total;
    if (processed == null || total == null || total <= 0) return null;
    return '$processed / $total';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasProgress = widget.progress != null && widget.error == null;
    final progressValue = hasProgress ? _displayProgress : null;

    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        final t = _orbController.value;
        final size = MediaQuery.sizeOf(context);

        return ColoredBox(
          color: _beige,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [
                      _beige,
                      _beigeDeep,
                    ],
                  ),
                ),
              ),
              for (final orb in _orbs)
                _FloatingOrb(
                  color: orb.color,
                  size: orb.size,
                  offset: _orbOffset(size, orb, t),
                ),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.white.withValues(alpha: 0.38),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B7355).withValues(alpha: 0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.showIndicator && widget.error == null) ...[
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: const Color(0xFF5C4F45),
                              value: progressValue,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        SizedBox(
                          height: 28,
                          child: _ThrottledCrossfadeText(
                            text: widget.message,
                            minHold: const Duration(milliseconds: 1200),
                            fadeDuration: const Duration(milliseconds: 360),
                            style: textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF4A3F38),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 44,
                          child: _ThrottledCrossfadeText(
                            text: widget.detail,
                            minHold: const Duration(milliseconds: 900),
                            fadeDuration: const Duration(milliseconds: 340),
                            style: textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B5E54),
                              height: 1.35,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 22,
                          child: _ThrottledCrossfadeText(
                            text: _countLabel,
                            minHold: const Duration(milliseconds: 600),
                            fadeDuration: const Duration(milliseconds: 280),
                            style: textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF8A7B6F),
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        if (hasProgress) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              value: progressValue,
                              backgroundColor: const Color(0xFF5C4F45)
                                  .withValues(alpha: 0.12),
                              color: const Color(0xFF5C4F45),
                            ),
                          ),
                        ],
                        if (widget.error != null) ...[
                          const SizedBox(height: 12),
                          _ThrottledCrossfadeText(
                            text: widget.error,
                            minHold: Duration.zero,
                            fadeDuration: const Duration(milliseconds: 360),
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9A4A42),
                            ),
                          ),
                        ],
                        if (widget.onSkip != null) ...[
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: widget.onSkip,
                            child: Text(
                              widget.error != null
                                  ? 'Continue anyway'
                                  : 'Skip and open gallery',
                              style: textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF5C4F45),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThrottledCrossfadeText extends StatefulWidget {
  const _ThrottledCrossfadeText({
    required this.text,
    required this.minHold,
    required this.fadeDuration,
    this.style,
  });

  final String? text;
  final Duration minHold;
  final Duration fadeDuration;
  final TextStyle? style;

  @override
  State<_ThrottledCrossfadeText> createState() => _ThrottledCrossfadeTextState();
}

class _ThrottledCrossfadeTextState extends State<_ThrottledCrossfadeText> {
  String? _displayed;
  String? _pending;
  DateTime _visibleSince = DateTime.now();
  Timer? _timer;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _displayed = _normalize(widget.text);
    _visibleSince = DateTime.now();
  }

  @override
  void didUpdateWidget(covariant _ThrottledCrossfadeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _normalize(widget.text);
    if (next == _displayed || next == _pending) return;
    _pending = next;
    _scheduleReveal();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String? _normalize(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }

  void _scheduleReveal() {
    _timer?.cancel();
    final generation = ++_generation;

    final elapsed = DateTime.now().difference(_visibleSince);
    final wait = widget.minHold - elapsed;
    final delay = wait.isNegative ? Duration.zero : wait;

    _timer = Timer(delay, () {
      if (!mounted || generation != _generation) return;
      final next = _pending;
      if (next == _displayed) {
        _pending = null;
        return;
      }
      setState(() {
        _displayed = next;
        _pending = null;
        _visibleSince = DateTime.now();
      });
      if (_pending != null) {
        _scheduleReveal();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.fadeDuration,
      reverseDuration: widget.fadeDuration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: _displayed == null
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : Text(
              _displayed!,
              key: ValueKey(_displayed),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: widget.style,
            ),
    );
  }
}

class _OrbSpec {
  const _OrbSpec({
    required this.color,
    required this.size,
    required this.phase,
    required this.speed,
  });

  final Color color;
  final double size;
  final double phase;
  final double speed;
}

class _FloatingOrb extends StatelessWidget {
  const _FloatingOrb({
    required this.color,
    required this.size,
    required this.offset,
  });

  final Color color;
  final double size;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.72),
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
