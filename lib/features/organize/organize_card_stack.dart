import 'package:flutter/material.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/models/organize_models.dart';
import 'package:social_gallery/features/organize/organize_card.dart';

typedef OrganizeSwipeCallback = void Function(OrganizeSwipeDirection direction);

class OrganizeCardStack extends StatefulWidget {
  const OrganizeCardStack({
    super.key,
    required this.cards,
    required this.onSwipe,
    this.onDragDown,
  });

  final List<MediaItem> cards;
  final OrganizeSwipeCallback onSwipe;
  final VoidCallback? onDragDown;

  @override
  State<OrganizeCardStack> createState() => _OrganizeCardStackState();
}

class _OrganizeCardStackState extends State<OrganizeCardStack> {
  Offset _dragOffset = Offset.zero;
  static const _threshold = 80.0;

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    final visible = widget.cards.take(3).toList();
    final dragColor = _overlayColor();

    final maxHeight = MediaQuery.sizeOf(context).height * 0.55;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 96),
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
    );
  }

  Color? _overlayColor() {
    if (_dragOffset.dx < -30) return Colors.red.withValues(alpha: 0.35);
    if (_dragOffset.dx > 30) return Colors.orange.withValues(alpha: 0.35);
    if (_dragOffset.dy < -30) return Colors.blue.withValues(alpha: 0.35);
    if (_dragOffset.dy > 30) return Colors.green.withValues(alpha: 0.25);
    return null;
  }

  Widget _buildLayer(MediaItem item, int index, Color? dragColor) {
    final isTop = index == 0;
    final scale = 1.0 - (index * 0.04);
    final yOffset = index * 8.0;

    Widget card = OrganizeCard(item: item, overlayColor: isTop ? dragColor : null);

    if (isTop) {
      card = GestureDetector(
        onPanUpdate: (details) {
          setState(() => _dragOffset += details.delta);
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

    OrganizeSwipeDirection? direction;
    if (dx.abs() > dy.abs()) {
      if (dx < -_threshold) direction = OrganizeSwipeDirection.left;
      if (dx > _threshold) direction = OrganizeSwipeDirection.right;
    } else {
      if (dy < -_threshold) direction = OrganizeSwipeDirection.up;
      if (dy > _threshold) {
        widget.onDragDown?.call();
        setState(() => _dragOffset = Offset.zero);
        return;
      }
    }

    if (direction != null) {
      AppHaptics.medium();
      widget.onSwipe(direction);
    }
    setState(() => _dragOffset = Offset.zero);
  }
}
