import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';
import 'package:social_gallery/domain/models/media_item.dart';

final favoritesStreamProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(mediaRepositoryProvider).watchFavorites();
});
