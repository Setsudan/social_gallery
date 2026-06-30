import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/features/organize/organize_card.dart';
import 'package:social_gallery/features/organize/organize_folder_strip.dart';

typedef OrganizeSwipeCallback = void Function(OrganizeSwipeDirection direction);
typedef OrganizeFolderDropCallback = void Function(String folderPath);

/// Draggable card stack for organize: swipe gestures and folder drop strip.
class OrganizeCardStack extends ConsumerStatefulWidget {
  const OrganizeCardStack({
    super.key,
    required this.cards,
    required this.folders,
    required this.onSwipe,
    this.onFolderDrop,
    this.onFolderDragChanged,
  });

  final List<MediaItem> cards;
  final List<FolderInfo> folders;
  final OrganizeSwipeCallback onSwipe;
  final OrganizeFolderDropCallback? onFolderDrop;
  final ValueChanged<bool>? onFolderDragChanged;

  @override
  ConsumerState<OrganizeCardStack> createState() => _OrganizeCardStackState();
}

class _OrganizeCardStackState extends ConsumerState<OrganizeCardStack> {
  final _folderStripKey = GlobalKey<OrganizeFolderStripState>();
  Offset _dragOffset = Offset.zero;
  Offset? _dragGlobalPosition;
  String? _hoveredFolderPath;
  bool _isDraggingDown = false;

  static const _threshold = 80.0;
  static const _folderRevealThreshold = 28.0;

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = widget.cards.take(3).toList();
    final dragColor = _overlayColor();

    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;
    final motion = AppMotion.of(context, ref);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        Center(
          child: AnimatedPadding(
            duration: motion.fadeFast,
            curve: motion.enterCurve,
            padding: EdgeInsets.fromLTRB(
              24,
              48,
              24,
              _isDraggingDown ? 140 : 96,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 380,
                maxHeight: maxHeight,
              ),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (var i = visible.length - 1; i >= 0; i--)
                      _buildLayer(visible[i], i, dragColor),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSlide(
            duration: motion.fade,
            curve: _isDraggingDown ? motion.enterCurve : motion.exitCurve,
            offset: _isDraggingDown ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: motion.fadeFast,
              opacity: _isDraggingDown ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_isDraggingDown,
                child: OrganizeFolderStrip(
                  key: _folderStripKey,
                  folders: widget.folders,
                  hoveredFolderPath: _hoveredFolderPath,
                  dragGlobalPosition: _dragGlobalPosition,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color? _overlayColor() {
    if (_isDraggingDown) return Colors.green.withValues(alpha: 0.25);
    if (_dragOffset.dx < -30) return Colors.red.withValues(alpha: 0.35);
    if (_dragOffset.dx > 30) return Colors.orange.withValues(alpha: 0.35);
    if (_dragOffset.dy < -30) return Colors.blue.withValues(alpha: 0.35);
    return null;
  }

  Widget _buildLayer(MediaItem item, int index, Color? dragColor) {
    final isTop = index == 0;
    final scale = 1.0 - (index * 0.04);
    final yOffset = index * 8.0;

    Widget card = OrganizeCard(
      item: item,
      overlayColor: isTop ? dragColor : null,
      playbackActive: isTop,
    );

    if (isTop) {
      card = GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _dragOffset += details.delta;
            _dragGlobalPosition = details.globalPosition;
            final draggingDown = _dragOffset.dy > _folderRevealThreshold;
            _setDraggingDown(draggingDown);
            if (_isDraggingDown) {
              _hoveredFolderPath = _folderStripKey.currentState
                  ?.folderAt(details.globalPosition);
            } else {
              _hoveredFolderPath = null;
            }
          });
        },
        onPanEnd: (details) {
          _handleRelease(details.velocity);
        },
        child: Transform.translate(
          offset: _dragOffset,
          child: Transform.rotate(
            angle: _dragOffset.dx * 0.001,
            child: card,
          ),
        ),
      );
    } else {
      card = Transform.scale(
        scale: scale,
        child: Transform.translate(
          offset: Offset(0, yOffset),
          child: card,
        ),
      );
    }

    return Positioned.fill(child: card);
  }

  void _handleRelease(Velocity velocity) {
    final dx = _dragOffset.dx;
    final dy = _dragOffset.dy;

    if (_isDraggingDown) {
      final target = _hoveredFolderPath;
      _resetDrag();
      if (target != null) {
        AppHaptics.medium();
        widget.onFolderDrop?.call(target);
      }
      return;
    }

    OrganizeSwipeDirection? direction;
    if (dx.abs() > dy.abs()) {
      if (dx < -_threshold) direction = OrganizeSwipeDirection.left;
      if (dx > _threshold) direction = OrganizeSwipeDirection.right;
    } else {
      if (dy < -_threshold) direction = OrganizeSwipeDirection.up;
    }

    if (direction != null) {
      AppHaptics.medium();
      widget.onSwipe(direction);
    }
    _resetDrag();
  }

  void _setDraggingDown(bool draggingDown) {
    if (_isDraggingDown == draggingDown) return;
    _isDraggingDown = draggingDown;
    widget.onFolderDragChanged?.call(draggingDown);
  }

  void _resetDrag() {
    _setDraggingDown(false);
    setState(() {
      _dragOffset = Offset.zero;
      _dragGlobalPosition = null;
      _hoveredFolderPath = null;
    });
  }
}
