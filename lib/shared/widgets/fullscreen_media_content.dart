import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/media/asset_media_loader.dart';
import 'package:social_gallery/core/media/asset_media_kind.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/shared/widgets/asset_video_player.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/unsupported_media_placeholder.dart';

/// Edge-to-edge photo/video for post detail and media viewer routes.
class FullscreenMediaContent extends ConsumerWidget {
  const FullscreenMediaContent({
    super.key,
    this.entity,
    this.assetPath,
    this.heroTag,
    this.videoFit = BoxFit.contain,
    this.imageFit = BoxFit.contain,
    this.enablePinchZoom = true,
    this.isActive = true,
  });

  final AssetEntity? entity;
  final String? assetPath;
  final String? heroTag;
  final BoxFit videoFit;
  final BoxFit imageFit;
  final bool enablePinchZoom;

  /// When false, videos show a poster instead of initializing a player.
  final bool isActive;

  int _decodeCacheWidth(BuildContext context, Size size) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (size.shortestSide * dpr).ceil().clamp(720, 4096);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final cacheWidth = _decodeCacheWidth(context, size);

    if (usesFilesystemGallery && assetPath != null) {
      final isWinVideo = assetPath!.toLowerCase().endsWith('.mp4') ||
          assetPath!.toLowerCase().endsWith('.mov') ||
          assetPath!.toLowerCase().endsWith('.mkv') ||
          assetPath!.toLowerCase().endsWith('.webm') ||
          assetPath!.toLowerCase().endsWith('.avi');

      if (isWinVideo) {
        if (!isActive) {
          return MediaThumbnail(
            assetId: assetPath!,
            showVideoBadge: true,
            fit: BoxFit.contain,
          );
        }
        return AssetVideoPlayer(
          entity: null,
          assetPath: assetPath,
          fit: videoFit,
        );
      }

      final Widget imageChild = Image.file(
        File(assetPath!),
        fit: imageFit,
        cacheWidth: cacheWidth,
        gaplessPlayback: true,
      );

      final Widget routedImage = heroTag != null
          ? Hero(
              tag: heroTag!,
              flightShuttleBuilder: (
                flightContext,
                animation,
                flightDirection,
                fromHeroContext,
                toHeroContext,
              ) {
                final shuttleHero = flightDirection == HeroFlightDirection.pop
                    ? fromHeroContext.widget as Hero
                    : toHeroContext.widget as Hero;
                return SizedBox.expand(
                  child: FittedBox(fit: BoxFit.contain, child: shuttleHero.child),
                );
              },
              child: imageChild,
            )
          : imageChild;

      final mediaChild = SizedBox(
        width: size.width,
        height: size.height,
        child: routedImage,
      );

      if (!enablePinchZoom) {
        return SizedBox.expand(child: mediaChild);
      }

      return _FocalZoomViewer(
        motion: AppMotion.of(context, ref),
        child: mediaChild,
      );
    }

    final nonNullEntity = entity!;
    final kind = AssetMediaLoader.classify(nonNullEntity);

    if (kind == AssetMediaKind.video) {
      if (!isActive) {
        return MediaThumbnail(
          assetId: nonNullEntity.id,
          showVideoBadge: true,
          fit: BoxFit.contain,
        );
      }
      return AssetVideoPlayer(entity: nonNullEntity, fit: videoFit);
    }

    if (kind == AssetMediaKind.audio || kind == AssetMediaKind.unsupported) {
      return SizedBox.expand(
        child: UnsupportedMediaPlaceholder(
          kind: kind,
          entity: nonNullEntity,
          fit: BoxFit.contain,
        ),
      );
    }

    final imageChild = AssetMediaLoader.buildFullscreenImage(
      entity: nonNullEntity,
      fit: imageFit,
      heroTag: heroTag,
      cacheWidth: cacheWidth,
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
  bool _panEnabled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransformChanged);
    _animController = AnimationController(vsync: this)
      ..addStatusListener(_onAnimStatus);
    _onTransformChanged();
  }

  void _onTransformChanged() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > _zoomedThreshold;
    if (zoomed != _panEnabled) {
      setState(() => _panEnabled = zoomed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
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
          panEnabled: _panEnabled,
          minScale: 1,
          maxScale: 4,
          clipBehavior: Clip.none,
          child: widget.child,
        ),
      ),
    );
  }
}
