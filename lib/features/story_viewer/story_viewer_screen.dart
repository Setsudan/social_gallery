import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/core/animation/app_motion.dart';
import 'package:social_gallery/core/platform/desktop_gallery_platform.dart';
import 'package:social_gallery/core/utils/haptics.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/fullscreen_media_content.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, required this.folderPath});

  final String folderPath;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  List<MediaItem> _mediaList = [];
  int _currentIndex = 0;
  bool _loading = true;
  String? _error;

  Timer? _timer;
  double _progress = 0.0;
  static const Duration _storyDuration = Duration(seconds: 5);
  late DateTime _lastTickTime;
  Duration _elapsed = Duration.zero;
  bool _isPaused = false;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _loadStoryData();
  }

  Future<void> _loadStoryData() async {
    try {
      final repo = ref.read(mediaRepositoryProvider);

      // 1. Mark as viewed immediately so that home screen bubble updates
      await repo.markStoryAsViewed(widget.folderPath);

      // 2. Load folders with stories to get the items for this folder
      final folders = await repo.getFoldersWithStories();
      final currentFolder = folders
          .where((f) => f.folderPath == widget.folderPath)
          .firstOrNull;

      if (currentFolder == null || currentFolder.latestMedia.isEmpty) {
        setState(() {
          _error = 'No recent stories found in this folder.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _mediaList = currentFolder.latestMedia;
        _loading = false;
      });

      _startStoryTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startStoryTimer({Duration? elapsed}) {
    _timer?.cancel();
    _lastTickTime = DateTime.now();
    _elapsed = elapsed ?? Duration.zero;

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPaused) return;

      final now = DateTime.now();
      final delta = now.difference(_lastTickTime);
      _lastTickTime = now;
      _elapsed += delta;

      setState(() {
        _progress = _elapsed.inMilliseconds / _storyDuration.inMilliseconds;
      });

      if (_elapsed >= _storyDuration) {
        _timer?.cancel();
        _nextStory();
      }
    });
  }

  void _pause() {
    setState(() {
      _isPaused = true;
    });
  }

  void _resume() {
    if (!_isPaused) return;
    setState(() {
      _isPaused = false;
    });
    _startStoryTimer(elapsed: _elapsed);
  }

  void _nextStory() {
    if (_currentIndex < _mediaList.length - 1) {
      setState(() {
        _currentIndex++;
        _progress = 0.0;
      });
      AppHaptics.selection();
      _startStoryTimer();
    } else {
      // Completed last story, dismiss
      context.pop();
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _progress = 0.0;
      });
      AppHaptics.selection();
      _startStoryTimer();
    } else {
      // At first story, restart it
      setState(() {
        _progress = 0.0;
      });
      _startStoryTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white54,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentMedia = _mediaList[_currentIndex];
    final motion = AppMotion.of(context, ref);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 12) {
              AppHaptics.light();
              context.pop();
            }
          },
          onLongPressStart: (_) => _pause(),
          onLongPressEnd: (_) => _resume(),
          onTapUp: (details) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final tapX = details.localPosition.dx;
            if (tapX > screenWidth * 0.35 && tapX < screenWidth * 0.65) {
              setState(() => _showChrome = !_showChrome);
            } else if (tapX < screenWidth * 0.3) {
              _prevStory();
            } else {
              _nextStory();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Viewer
              Positioned.fill(
                child: usesFilesystemGallery
                    ? FullscreenMediaContent(
                        entity: null,
                        assetPath: currentMedia.uri,
                        videoFit: BoxFit.contain,
                        imageFit: BoxFit.contain,
                        enablePinchZoom: false,
                      )
                    : FutureBuilder<AssetEntity?>(
                        future: AssetEntity.fromId(currentMedia.uri),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            );
                          }

                          final entity = snapshot.data;
                          if (entity == null) {
                            return const Center(
                              child: Text(
                                'Media not found',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }

                          return FullscreenMediaContent(
                            entity: entity,
                            videoFit: BoxFit.contain,
                            imageFit: BoxFit.contain,
                            enablePinchZoom: false,
                          );
                        },
                      ),
              ),

              Positioned(
                top: 48,
                left: 12,
                right: 12,
                child: AnimatedOpacity(
                  duration: motion.fade,
                  opacity: _showChrome ? 1 : 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: List.generate(_mediaList.length, (index) {
                          double segmentProgress = 0.0;
                          if (index < _currentIndex) {
                            segmentProgress = 1.0;
                          } else if (index == _currentIndex) {
                            segmentProgress = _progress;
                          }

                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedContainer(
                                      duration: motion.fadeFast,
                                      curve: motion.enterCurve,
                                      width:
                                          constraints.maxWidth *
                                          segmentProgress,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            radius: 18,
                            child: Text(
                              currentMedia.folderName.isNotEmpty
                                  ? currentMedia.folderName
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : 'A',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentMedia.folderName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currentMedia.displayName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              AppHaptics.light();
                              context.pop();
                            },
                          ),
                        ],
                      ),
                    ],
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
