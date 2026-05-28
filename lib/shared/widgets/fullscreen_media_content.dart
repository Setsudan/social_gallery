import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/media/asset_media_kind.dart';
import 'package:social_gallery/shared/widgets/asset_video_player.dart';
import 'package:social_gallery/shared/widgets/unsupported_media_placeholder.dart';

/// Edge-to-edge photo/video for post detail and media viewer routes.
class FullscreenMediaContent extends ConsumerWidget {
  const FullscreenMediaContent({
    super.key,
    required this.entity,
    this.heroTag,
    this.videoFit = BoxFit.contain,
    this.imageFit = BoxFit.contain,
    this.enablePinchZoom = true,
  });

  final AssetEntity entity;
  final String? heroTag;
  final BoxFit videoFit;
  final BoxFit imageFit;
  final bool enablePinchZoom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = AssetMediaLoader.classify(entity);
    final size = MediaQuery.sizeOf(context);

    if (kind == AssetMediaKind.video) {
      return AssetVideoPlayer(entity: entity, fit: videoFit);
    }

    if (kind == AssetMediaKind.audio || kind == AssetMediaKind.unsupported) {
      return SizedBox.expand(
        child: UnsupportedMediaPlaceholder(
          kind: kind,
          entity: entity,
          fit: BoxFit.contain,
        ),
      );
    }

    final imageChild = AssetMediaLoader.buildFullscreenImage(
      entity: entity,
      fit: imageFit,
      heroTag: heroTag,
    );

    final mediaChild = SizedBox(
      width: size.width,
      height: size.height,
      child: imageChild,
    );

    if (!enablePinchZoom) {
      return SizedBox.expand(child: mediaChild);
    }

    return _FocalZoomViewer(
      motion: AppMotion.of(context, ref),
      child: mediaChild,
    );
  }
}

class _FocalZoomViewer extends StatefulWidget {
  const _FocalZoomViewer({required this.child, required this.motion});

  final Widget child;
  final AppMotion motion;

  @override
  State<_FocalZoomViewer> createState() => _FocalZoomViewerState();
}

class _FocalZoomViewerState extends State<_FocalZoomViewer>
    with SingleTickerProviderStateMixin {
  static const double _zoomScale = 2.5;
  static const double _zoomedThreshold = 1.05;

  final TransformationController _controller = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _matrixAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this)
      ..addStatusListener(_onAnimStatus);
  }

  @override
  void dispose() {
    _matrixAnimation?.removeListener(_onMatrixTick);
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onAnimStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _matrixAnimation?.removeListener(_onMatrixTick);
    _matrixAnimation = null;
  }

  void _onMatrixTick() {
    final animation = _matrixAnimation;
    if (animation == null) return;
    _controller.value = animation.value;
  }

  Matrix4 _matrixForScale(double scale, Offset focal) {
    return Matrix4.identity()
      ..translateByDouble(focal.dx, focal.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-focal.dx, -focal.dy, 0, 1);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final zoomedIn = currentScale > _zoomedThreshold;
    final end = zoomedIn
        ? Matrix4.identity()
        : _matrixForScale(_zoomScale, details.localPosition);

    _matrixAnimation?.removeListener(_onMatrixTick);
    _animController.stop();

    if (!widget.motion.enabled) {
      _controller.value = end;
      return;
    }

    _matrixAnimation =
        Matrix4Tween(begin: _controller.value.clone(), end: end).animate(
          CurvedAnimation(
            parent: _animController,
            curve: widget.motion.enterCurve,
          ),
        )..addListener(_onMatrixTick);

    _animController
      ..duration = widget.motion.fade
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        onDoubleTapDown: _onDoubleTapDown,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1,
          maxScale: 4,
          clipBehavior: Clip.none,
          child: widget.child,
        ),
      ),
    );
  }
}
