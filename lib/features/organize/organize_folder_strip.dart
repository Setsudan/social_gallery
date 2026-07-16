import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:social_gallery/domain/models/folder_info.dart';
import 'package:social_gallery/shared/widgets/folder_avatar.dart';

class OrganizeFolderStrip extends StatefulWidget {
  const OrganizeFolderStrip({
    super.key,
    required this.folders,
    required this.dragGlobal,
    required this.hoveredFolderPath,
  });

  final List<FolderInfo> folders;
  final ValueListenable<Offset?> dragGlobal;
  final ValueNotifier<String?> hoveredFolderPath;

  @override
  OrganizeFolderStripState createState() => OrganizeFolderStripState();
}

class OrganizeFolderStripState extends State<OrganizeFolderStrip>
    with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();
  final _folderKeys = <String, GlobalKey>{};
  final _hitRects = <String, Rect>{};
  Ticker? _edgeScrollTicker;
  double _edgeScrollVelocityPxPerSec = 0;
  Duration? _lastTick;
  bool _hitCacheDirty = true;

  static const itemWidth = 80.0;
  static const separatorWidth = 10.0;
  static const listHeight = 96.0;

  @override
  void initState() {
    super.initState();
    _edgeScrollTicker = createTicker(_onEdgeScrollTick);
    widget.dragGlobal.addListener(_onDragGlobalChanged);
    _scrollController.addListener(_markHitCacheDirty);
  }

  @override
  void didUpdateWidget(OrganizeFolderStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dragGlobal != widget.dragGlobal) {
      oldWidget.dragGlobal.removeListener(_onDragGlobalChanged);
      widget.dragGlobal.addListener(_onDragGlobalChanged);
    }
    if (!listEquals(
      oldWidget.folders.map((f) => f.path).toList(),
      widget.folders.map((f) => f.path).toList(),
    )) {
      _markHitCacheDirty();
    }
  }

  @override
  void dispose() {
    widget.dragGlobal.removeListener(_onDragGlobalChanged);
    _scrollController.removeListener(_markHitCacheDirty);
    _edgeScrollTicker?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markHitCacheDirty() {
    _hitCacheDirty = true;
  }

  void _onDragGlobalChanged() {
    _updateEdgeScroll(widget.dragGlobal.value);
  }

  void _onEdgeScrollTick(Duration elapsed) {
    if (_edgeScrollVelocityPxPerSec == 0 || !_scrollController.hasClients) {
      return;
    }

    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return;

    final dtSec = (elapsed - last).inMicroseconds / 1e6;
    if (dtSec <= 0) return;

    final position = _scrollController.position;
    final next = (_scrollController.offset +
            _edgeScrollVelocityPxPerSec * dtSec)
        .clamp(0.0, position.maxScrollExtent);
    if (next != _scrollController.offset) {
      _scrollController.jumpTo(next);
      _markHitCacheDirty();
    }
  }

  void _updateEdgeScroll(Offset? globalPos) {
    if (globalPos == null || !mounted) {
      _edgeScrollVelocityPxPerSec = 0;
      _lastTick = null;
      _edgeScrollTicker?.stop();
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final inBottomDragZone = globalPos.dy > screenHeight - 180;
    if (!inBottomDragZone) {
      _edgeScrollVelocityPxPerSec = 0;
      _lastTick = null;
      _edgeScrollTicker?.stop();
      return;
    }

    final local = box.globalToLocal(globalPos);
    const zone = 56.0;
    const maxSpeedPxPerSec = 640.0;

    if (local.dx < zone) {
      _edgeScrollVelocityPxPerSec =
          -maxSpeedPxPerSec * (1 - (local.dx / zone).clamp(0.0, 1.0));
      if (!(_edgeScrollTicker?.isActive ?? false)) {
        _lastTick = null;
        _edgeScrollTicker?.start();
      }
    } else if (local.dx > box.size.width - zone) {
      final fromRight = box.size.width - local.dx;
      _edgeScrollVelocityPxPerSec =
          maxSpeedPxPerSec * (1 - (fromRight / zone).clamp(0.0, 1.0));
      if (!(_edgeScrollTicker?.isActive ?? false)) {
        _lastTick = null;
        _edgeScrollTicker?.start();
      }
    } else {
      _edgeScrollVelocityPxPerSec = 0;
      _lastTick = null;
      _edgeScrollTicker?.stop();
    }
  }

  void _rebuildHitCacheIfNeeded() {
    if (!_hitCacheDirty) return;
    _hitRects.clear();
    for (final folder in widget.folders) {
      final key = _folderKeys[folder.path];
      final box = key?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final origin = box.localToGlobal(Offset.zero);
      _hitRects[folder.path] = origin & box.size;
    }
    _hitCacheDirty = false;
  }

  String? folderAt(Offset globalPosition) {
    _rebuildHitCacheIfNeeded();
    for (final entry in _hitRects.entries) {
      if (entry.value.contains(globalPosition)) {
        return entry.key;
      }
    }

    // Fallback while first layout is settling.
    if (_hitRects.isEmpty) {
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
                height: listHeight,
                child: widget.folders.isEmpty
                    ? Center(
                        child: Text(
                          'No folders available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : NotificationListener<ScrollNotification>(
                        onNotification: (_) {
                          _markHitCacheDirty();
                          return false;
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.folders.length,
                          separatorBuilder: (_, index) =>
                              const SizedBox(width: separatorWidth),
                          itemBuilder: (context, index) {
                            final folder = widget.folders[index];
                            return _FolderDropTarget(
                              key: _keyFor(folder.path),
                              folder: folder,
                              folderPath: folder.path,
                              hoveredFolderPath: widget.hoveredFolderPath,
                            );
                          },
                        ),
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
    required this.folderPath,
    required this.hoveredFolderPath,
  });

  final FolderInfo folder;
  final String folderPath;
  final ValueListenable<String?> hoveredFolderPath;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: hoveredFolderPath,
      builder: (context, hoveredPath, child) {
        final hovered = hoveredPath == folderPath;
        final theme = Theme.of(context);
        final borderColor = hovered
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: hovered ? 2.5 : 1,
            ),
            color: hovered
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
          ),
          child: SizedBox(
            width: OrganizeFolderStripState.itemWidth,
            height: OrganizeFolderStripState.listHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  child!,
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      folder.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight:
                            hovered ? FontWeight.w700 : FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: RepaintBoundary(
        child: FolderAvatar(
          name: folder.name,
          size: 40,
          coverUri: folder.displayCoverUri,
          locked: folder.isLockedAccount,
        ),
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
