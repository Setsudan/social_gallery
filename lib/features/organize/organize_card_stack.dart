import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/l10n/l10n_extensions.dart';
import 'package:social_gallery/core/l10n/l10n_labels.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/features/organize/organize_card.dart';
import 'package:social_gallery/features/organize/organize_folder_strip.dart';

typedef OrganizeSwipeCallback = void Function(OrganizeSwipeDirection direction);
typedef OrganizeFolderDropCallback = void Function(String folderPath);

enum _OverlayBand { none, left, right, up, down }

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
  final _dragOffset = ValueNotifier(Offset.zero);
  final _dragGlobal = ValueNotifier<Offset?>(null);
  final _hoveredFolder = ValueNotifier<String?>(null);
  final _overlayBand = ValueNotifier(_OverlayBand.none);
  bool _isDraggingDown = false;

  static const _threshold = 80.0;
  static const _folderRevealThreshold = 28.0;
  static const _colorThreshold = 30.0;

  @override
  void dispose() {
    _dragOffset.dispose();
    _dragGlobal.dispose();
    _hoveredFolder.dispose();
    _overlayBand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = widget.cards.take(3).toList();
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
                      _buildLayer(visible[i], i),
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
                  dragGlobal: _dragGlobal,
                  hoveredFolderPath: _hoveredFolder,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLayer(MediaItem item, int index) {
    final isTop = index == 0;
    final scale = 1.0 - (index * 0.04);
    final yOffset = index * 8.0;

    Widget card = RepaintBoundary(
      child: OrganizeCard(
        item: item,
        playbackActive: isTop && !_isDraggingDown,
      ),
    );

    if (isTop) {
      card = Stack(
        fit: StackFit.expand,
        children: [
          card,
          ValueListenableBuilder<_OverlayBand>(
            valueListenable: _overlayBand,
            builder: (context, band, _) {
              if (band == _OverlayBand.none) {
                return const SizedBox.shrink();
              }
              final direction = _directionForBand(band);
              final action = _mapping.actionFor(direction);
              final color = _colorForAction(action);
              if (color == null) return const SizedBox.shrink();
              final actionLabel =
                  organizeSwipeActionLabel(context.l10n, action);
              return IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: color,
                  ),
                  child: Center(
                    child: Text(
                      actionLabel,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: const [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );

      final l10n = context.l10n;
      final mapping = _mapping;
      final semanticHint =
          '${l10n.organizeSwipeHintLeft(organizeSwipeActionLabel(l10n, mapping.left))}. '
          '${l10n.organizeSwipeHintRight(organizeSwipeActionLabel(l10n, mapping.right))}. '
          '${l10n.organizeSwipeHintUp(organizeSwipeActionLabel(l10n, mapping.up))}. '
          '${l10n.organizeSwipeHintDown(organizeSwipeActionLabel(l10n, mapping.down))}';
      card = Semantics(
        explicitChildNodes: true,
        label: l10n.organizeCardSemanticLabel(item.displayName, item.folderName),
        hint: semanticHint,
        child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: (details) => _handleRelease(details.velocity),
        child: ValueListenableBuilder<Offset>(
          valueListenable: _dragOffset,
          builder: (context, offset, child) {
            return Transform.translate(
              offset: offset,
              child: Transform.rotate(
                angle: offset.dx * 0.001,
                child: child,
              ),
            );
          },
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

  void _onPanUpdate(DragUpdateDetails details) {
    final next = _dragOffset.value + details.delta;
    _dragOffset.value = next;
    _dragGlobal.value = details.globalPosition;

    final draggingDown = _downIsMove && next.dy > _folderRevealThreshold;
    _setDraggingDown(draggingDown);

    if (draggingDown) {
      final hovered = _folderStripKey.currentState?.folderAt(
        details.globalPosition,
      );
      if (_hoveredFolder.value != hovered) {
        _hoveredFolder.value = hovered;
      }
    } else if (_hoveredFolder.value != null) {
      _hoveredFolder.value = null;
    }

    final band = _bandForOffset(next, folderStripActive: draggingDown);
    if (_overlayBand.value != band) {
      _overlayBand.value = band;
    }
  }

  /// Overlay bands follow the drag axis. Folder-strip drag ([folderStripActive])
  /// forces the down band (mapped move). When down is remapped away from move,
  /// a downward drag still gets a down overlay via the dy threshold.
  _OverlayBand _bandForOffset(Offset offset, {required bool folderStripActive}) {
    if (folderStripActive) return _OverlayBand.down;
    if (offset.dx < -_colorThreshold) return _OverlayBand.left;
    if (offset.dx > _colorThreshold) return _OverlayBand.right;
    if (offset.dy < -_colorThreshold) return _OverlayBand.up;
    if (offset.dy > _colorThreshold) return _OverlayBand.down;
    return _OverlayBand.none;
  }

  OrganizeGestureMapping get _mapping =>
      ref.read(settingsProvider).organizeGestureMapping;

  bool get _downIsMove =>
      _mapping.down == OrganizeSwipeAction.move;

  Color? _colorForAction(OrganizeSwipeAction action) {
    return switch (action) {
      OrganizeSwipeAction.trash => Colors.red.withValues(alpha: 0.35),
      OrganizeSwipeAction.favorite => Colors.orange.withValues(alpha: 0.35),
      OrganizeSwipeAction.keep => Colors.blue.withValues(alpha: 0.35),
      OrganizeSwipeAction.move => Colors.green.withValues(alpha: 0.25),
    };
  }

  OrganizeSwipeDirection _directionForBand(_OverlayBand band) {
    return switch (band) {
      _OverlayBand.left => OrganizeSwipeDirection.left,
      _OverlayBand.right => OrganizeSwipeDirection.right,
      _OverlayBand.up => OrganizeSwipeDirection.up,
      _OverlayBand.down => OrganizeSwipeDirection.down,
      _OverlayBand.none => OrganizeSwipeDirection.down,
    };
  }
  void _handleRelease(Velocity velocity) {
    final dx = _dragOffset.value.dx;
    final dy = _dragOffset.value.dy;

    if (_isDraggingDown && _downIsMove) {
      final target = _hoveredFolder.value;
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
      if (dy > _threshold && !_downIsMove) {
        direction = OrganizeSwipeDirection.down;
      }
    }

    if (direction != null) {
      AppHaptics.medium();
      widget.onSwipe(direction);
    }
    _resetDrag();
  }

  void _setDraggingDown(bool draggingDown) {
    if (_isDraggingDown == draggingDown) return;
    setState(() => _isDraggingDown = draggingDown);
    widget.onFolderDragChanged?.call(draggingDown);
  }

  void _resetDrag() {
    _setDraggingDown(false);
    _dragOffset.value = Offset.zero;
    _dragGlobal.value = null;
    _hoveredFolder.value = null;
    _overlayBand.value = _OverlayBand.none;
  }
}
