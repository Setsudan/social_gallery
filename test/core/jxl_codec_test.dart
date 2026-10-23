import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:social_gallery/core/media/jxl_codec.dart';

void main() {
  late Uint8List fixtureBytes;

  setUpAll(() {
    fixtureBytes = File('test/fixtures/sample.jxl').readAsBytesSync();
  });

  test('isJxlPath detects extension', () {
    expect(isJxlPath(r'C:\photos\shot.jxl'), isTrue);
    expect(isJxlPath(r'C:\photos\shot.JXL'), isTrue);
    expect(isJxlPath(r'C:\photos\shot.jpg'), isFalse);
  });

  test('isJxlBytes sniffs fixture', () {
    expect(isJxlBytes(fixtureBytes), isTrue);
    expect(isJxlBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF])), isFalse);
  });

  test('readJxlDimensions returns fixture size', () {
    final dims = readJxlDimensions(fixtureBytes);
    expect(dims, isNotNull);
    expect(dims!.width, 2);
    expect(dims.height, 2);
  });

  test('decodeJxlToPackageImage yields pixels', () {
    final image = decodeJxlToPackageImage(fixtureBytes);
    expect(image, isNotNull);
    expect(image!.width, 2);
    expect(image.height, 2);
  });

  test('decodeRasterImage handles jxl', () {
    final image = decodeRasterImage(fixtureBytes);
    expect(image, isNotNull);
    expect(image!.width, 2);
    expect(image.height, 2);
  });
}
