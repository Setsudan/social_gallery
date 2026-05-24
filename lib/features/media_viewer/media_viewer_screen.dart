import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/shared/widgets/asset_video_player.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.assetId,
    required this.mediaId,
    this.initialFavorite = false,
  });

  final String assetId;
  final int mediaId;
  final bool initialFavorite;

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late bool _favorite;

  @override
  void initState() {
    super.initState();
    _favorite = widget.initialFavorite;
  }

  Future<void> _toggleFavorite() async {
    final next = !_favorite;
    await ref.read(mediaRepositoryProvider).setFavorite(widget.mediaId, next);
    setState(() => _favorite = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _favorite ? Icons.favorite : Icons.favorite_border,
              color: _favorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: FutureBuilder<AssetEntity?>(
        future: AssetEntity.fromId(widget.assetId),
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

          if (entity.type == AssetType.video) {
            return AssetVideoPlayer(entity: entity);
          }

          return Center(
            child: InteractiveViewer(
              child: Image(
                image: AssetEntityImageProvider(
                  entity,
                  isOriginal: true,
                ),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
