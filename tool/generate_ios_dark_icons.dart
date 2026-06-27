import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

/// Generates dark-appearance iOS AppIcon PNGs and updates Contents.json.
Future<void> main() async {
  final projectRoot = Directory.current.path.endsWith('tool')
      ? Directory.current.parent.path
      : Directory.current.path;
  final sourcePath = '$projectRoot/assets/icons/app_icon_dark.png';
  final appIconDir = Directory(
    '$projectRoot/ios/Runner/Assets.xcassets/AppIcon.appiconset',
  );
  final contentsFile = File('${appIconDir.path}/Contents.json');

  final sourceBytes = await File(sourcePath).readAsBytes();
  final source = img.decodeImage(sourceBytes);
  if (source == null) {
    throw StateError('Could not decode $sourcePath');
  }

  const entries = <({String filename, int pixels})>[
    (filename: 'Icon-App-20x20@1x-dark.png', pixels: 20),
    (filename: 'Icon-App-20x20@2x-dark.png', pixels: 40),
    (filename: 'Icon-App-20x20@3x-dark.png', pixels: 60),
    (filename: 'Icon-App-29x29@1x-dark.png', pixels: 29),
    (filename: 'Icon-App-29x29@2x-dark.png', pixels: 58),
    (filename: 'Icon-App-29x29@3x-dark.png', pixels: 87),
    (filename: 'Icon-App-40x40@1x-dark.png', pixels: 40),
    (filename: 'Icon-App-40x40@2x-dark.png', pixels: 80),
    (filename: 'Icon-App-40x40@3x-dark.png', pixels: 120),
    (filename: 'Icon-App-50x50@1x-dark.png', pixels: 50),
    (filename: 'Icon-App-50x50@2x-dark.png', pixels: 100),
    (filename: 'Icon-App-57x57@1x-dark.png', pixels: 57),
    (filename: 'Icon-App-57x57@2x-dark.png', pixels: 114),
    (filename: 'Icon-App-60x60@2x-dark.png', pixels: 120),
    (filename: 'Icon-App-60x60@3x-dark.png', pixels: 180),
    (filename: 'Icon-App-72x72@1x-dark.png', pixels: 72),
    (filename: 'Icon-App-72x72@2x-dark.png', pixels: 144),
    (filename: 'Icon-App-76x76@1x-dark.png', pixels: 76),
    (filename: 'Icon-App-76x76@2x-dark.png', pixels: 152),
    (filename: 'Icon-App-83.5x83.5@2x-dark.png', pixels: 167),
    (filename: 'Icon-App-1024x1024@1x-dark.png', pixels: 1024),
  ];

  for (final entry in entries) {
    final resized = img.copyResize(
      source,
      width: entry.pixels,
      height: entry.pixels,
      interpolation: img.Interpolation.cubic,
    );
    await File('${appIconDir.path}/${entry.filename}')
        .writeAsBytes(img.encodePng(resized));
  }

  final decoded =
      jsonDecode(await contentsFile.readAsString()) as Map<String, dynamic>;
  final images = (decoded['images'] as List).cast<Map<String, dynamic>>();
  final updatedImages = <Map<String, dynamic>>[];

  for (final image in images) {
    updatedImages.add(Map<String, dynamic>.from(image));
    final filename = image['filename'] as String?;
    if (filename == null || filename.contains('-dark')) {
      continue;
    }

    final darkEntry = Map<String, dynamic>.from(image);
    darkEntry['filename'] = _darkFilename(filename);
    darkEntry['appearances'] = [
      {
        'appearance': 'luminosity',
        'value': 'dark',
      },
    ];
    updatedImages.add(darkEntry);
  }

  decoded['images'] = updatedImages;
  const encoder = JsonEncoder.withIndent('  ');
  await contentsFile.writeAsString('${encoder.convert(decoded)}\n');
  stdout.writeln('Generated ${entries.length} dark iOS icons.');
}

String _darkFilename(String lightFilename) {
  final dot = lightFilename.lastIndexOf('.');
  if (dot == -1) {
    return '$lightFilename-dark';
  }
  return '${lightFilename.substring(0, dot)}-dark${lightFilename.substring(dot)}';
}
