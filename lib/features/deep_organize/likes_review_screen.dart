import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/shared/widgets/media_thumbnail.dart';
import 'package:social_gallery/shared/widgets/one_ui/one_ui_page_header.dart';

class LikesReviewScreen extends ConsumerStatefulWidget {
  const LikesReviewScreen({super.key});

  @override
  ConsumerState<LikesReviewScreen> createState() => _LikesReviewScreenState();
}

class _LikesReviewScreenState extends ConsumerState<LikesReviewScreen> {
  final _pageController = PageController();
  List<MediaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await ref.read(mediaRepositoryProvider).getFavoriteMediaList();
    items.shuffle(Random());
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                final index = _pageController.hasClients
                    ? (_pageController.page ?? 0).round()
                    : 0;
                if (index < _items.length) {
                  Share.share('Sharing ${_items[index].displayName}');
                }
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OneUiPageHeader(
                  title: 'Likes review',
                  subtitle: 'Swipe right in Organize to favorite photos.',
                ),
                Expanded(child: Center(child: Text('No liked items yet.'))),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OneUiPageHeader(
                  title: 'Likes review',
                  subtitle: 'Scroll through your favorites.',
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: item.isVideo
                                    ? MediaThumbnail(
                                        assetId: item.uri,
                                        showVideoBadge: true,
                                      )
                                    : MediaThumbnail(
                                        assetId: item.uri,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.displayName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              item.folderName,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
