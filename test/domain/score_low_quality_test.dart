import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/domain/models/media_analysis_result.dart';
import 'package:social_gallery/domain/models/media_item.dart';
import 'package:social_gallery/domain/usecases/score_low_quality.dart';

MediaItem _item({
  required int id,
  int width = 100,
  int height = 100,
  int size = 1000,
}) {
  return MediaItem(
    id: id,
    uri: 'uri_$id',
    displayName: 'img_$id.jpg',
    folderName: 'Folder',
    folderPath: 'folder',
    dateAdded: 1,
    dateModified: 1,
    size: size,
    mimeType: 'image/jpeg',
    width: width,
    height: height,
  );
}

void main() {
  final score = ScoreLowQuality();

  test('flags blur and small file issues', () {
    final items = [_item(id: 1, width: 200, height: 200, size: 1000)];
    final analysis = {
      1: const MediaAnalysisResult(
        mediaId: 1,
        blurScore: 10,
        scannedAt: 1,
      ),
    };

    final results = score(items: items, analysisById: analysis);
    expect(results.length, 1);
    expect(results.first.reasons, contains('Blurry'));
    expect(results.first.reasons, contains('Small file'));
    expect(results.first.reasons, contains('Low resolution'));
  });
}
