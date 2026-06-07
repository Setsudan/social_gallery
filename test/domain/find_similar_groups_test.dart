import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/find_similar_groups.dart';

MediaItem _item(int id, int sortDate) {
  return MediaItem(
    id: id,
    uri: 'uri_$id',
    displayName: 'img_$id.jpg',
    folderName: 'Folder',
    folderPath: 'folder',
    dateAdded: sortDate,
    dateModified: sortDate,
    dateTaken: sortDate,
    size: 1000,
    mimeType: 'image/jpeg',
    width: 100,
    height: 100,
  );
}

void main() {
  final findSimilar = FindSimilarGroups();

  test('groups items with close hashes within time window', () {
    final t = 1_000_000;
    final items = [_item(1, t), _item(2, t + 1000), _item(3, t + 10_000_000)];
    final analysis = {
      1: MediaAnalysisResult(
        mediaId: 1,
        dHash: '0000000000000000000000000000000000000000000000000000000000000000',
        scannedAt: 1,
      ),
      2: MediaAnalysisResult(
        mediaId: 2,
        dHash: '0000000000000000000000000000000000000000000000000000000000000001',
        scannedAt: 1,
      ),
      3: MediaAnalysisResult(
        mediaId: 3,
        dHash: '1111111111111111111111111111111111111111111111111111111111111111',
        scannedAt: 1,
      ),
    };

    final groups = findSimilar(items: items, analysisById: analysis);
    expect(groups.length, 1);
    expect(groups.first.mediaIds, [1, 2]);
  });
}
