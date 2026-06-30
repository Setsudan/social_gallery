import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';

class OrganizeFolderStrip extends StatefulWidget {
  const OrganizeFolderStrip({
    super.key,
    required this.folders,
    this.hoveredFolderPath,
    this.dragGlobalPosition,
  });

  final List<FolderInfo> folders;
  final String? hoveredFolderPath;
  final Offset? dragGlobalPosition;

  @override
  OrganizeFolderStripState createState() => OrganizeFolderStripState();
}

class OrganizeFolderStripState extends State<OrganizeFolderStrip>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _folderKeys = <String, GlobalKey>{};
  Ticker? _edgeScrollTicker;
  double _edgeScrollVelocity = 0;

  @override
  void initState() {
    super.initState();
    _edgeScrollTicker = createTicker(_onEdgeScrollTick);
  }

  @override
  void didUpdateWidget(OrganizeFolderStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dragGlobalPosition != widget.dragGlobalPosition) {
      _updateEdgeScroll(widget.dragGlobalPosition);
    }
  }

  @override
  void dispose() {
    _edgeScrollTicker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onEdgeScrollTick(Duration elapsed) {
    if (_edgeScrollVelocity == 0 || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final next = (_scrollController.offset + _edgeScrollVelocity)
        .clamp(0.0, position.maxScrollExtent);
    if (next != _scrollController.offset) {
      _scrollController.jumpTo(next);
    }
  }

  void _updateEdgeScroll(Offset? globalPos) {
    if (globalPos == null || !mounted) {
      _edgeScrollVelocity = 0;
      _edgeScrollTicker?.stop();
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final inBottomDragZone = globalPos.dy > screenHeight - 180;
    if (!inBottomDragZone) {
      _edgeScrollVelocity = 0;
      _edgeScrollTicker?.stop();
      return;
    }

    final local = box.globalToLocal(globalPos);
    const zone = 56.0;
    const maxSpeed = 10.0;

    if (local.dx < zone) {
      _edgeScrollVelocity = -maxSpeed * (1 - (local.dx / zone).clamp(0.0, 1.0));
      if (!(_edgeScrollTicker?.isActive ?? false)) {
        _edgeScrollTicker?.start();
      }
    } else if (local.dx > box.size.width - zone) {
      final fromRight = box.size.width - local.dx;
      _edgeScrollVelocity =
          maxSpeed * (1 - (fromRight / zone).clamp(0.0, 1.0));
      if (!(_edgeScrollTicker?.isActive ?? false)) {
        _edgeScrollTicker?.start();
      }
    } else {
      _edgeScrollVelocity = 0;
      _edgeScrollTicker?.stop();
    }
  }

  String? folderAt(Offset globalPosition) {
    for (final folder in widget.folders) {
      final key = _folderKeys[folder.path];
      final box = key?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final local = box.globalToLocal(globalPosition);
      if (local.dx >= 0 &&
          local.dy >= 0 &&
          local.dx <= box.size.width &&
          local.dy <= box.size.height) {
        return folder.path;
      }
    }
    return null;
  }

  GlobalKey _keyFor(String path) =>
      _folderKeys.putIfAbsent(path, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Drop on a folder',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: widget.folders.isEmpty
                    ? Center(
                        child: Text(
                          'No folders available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.folders.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final folder = widget.folders[index];
                          final hovered =
                              widget.hoveredFolderPath == folder.path;
                          return _FolderDropTarget(
                            key: _keyFor(folder.path),
                            folder: folder,
                            hovered: hovered,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FolderDropTarget extends StatelessWidget {
  const _FolderDropTarget({
    super.key,
    required this.folder,
    required this.hovered,
  });

  final FolderInfo folder;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = hovered
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 80,
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: hovered ? 2.5 : 1,
        ),
        color: hovered
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FolderAvatar(
            name: folder.name,
            size: 40,
            coverUri: folder.displayCoverUri,
            locked: folder.isLockedAccount,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              folder.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: hovered ? FontWeight.w700 : FontWeight.w500,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<FolderInfo> sortFoldersByRecent(
  List<FolderInfo> all,
  List<String> recentPaths,
) {
  final byPath = {for (final folder in all) folder.path: folder};
  final ordered = <FolderInfo>[];
  for (final path in recentPaths) {
    final folder = byPath.remove(path);
    if (folder != null) ordered.add(folder);
  }
  final rest = byPath.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return [...ordered, ...rest];
}
