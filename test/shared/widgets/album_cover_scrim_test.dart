import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/shared/widgets/album_cover_tile.dart';

void main() {
  testWidgets('album scrim does not blur the backdrop', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 160,
            child: AlbumCoverScrim(title: 'Trip', itemCount: 12),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('Trip'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });

  test('album cover file check is cached for the session', () {
    debugResetAlbumCoverExistsCache();
    final dir = Directory.systemTemp.createTempSync('album-cover');
    addTearDown(() {
      debugResetAlbumCoverExistsCache();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });
    final file = File('${dir.path}/cover.jpg')..writeAsStringSync('x');

    expect(albumCoverUriIsLocalFile(file.path), isTrue);
    file.deleteSync();
    expect(albumCoverUriIsLocalFile(file.path), isTrue);

    debugResetAlbumCoverExistsCache();
    expect(albumCoverUriIsLocalFile(file.path), isFalse);
    file.writeAsStringSync('y');
    expect(albumCoverUriIsLocalFile(file.path), isFalse);
  });
}
