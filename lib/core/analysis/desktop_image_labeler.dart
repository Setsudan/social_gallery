import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_litert/flutter_litert.dart';
import 'package:image/image.dart' as img;

/// On-device image labels for desktop using MobileNet V2 (Apache 2.0, TF model zoo).
class DesktopImageLabeler {
  DesktopImageLabeler._();

  static DesktopImageLabeler? _instance;
  static DesktopImageLabeler get instance =>
      _instance ??= DesktopImageLabeler._();

  static const _modelAsset = 'assets/ml/mobilenet_v2_1.0_224_quant.tflite';
  static const _labelsAsset = 'assets/ml/imagenet_labels.txt';
  static const _inputSize = 224;
  static const _maxLabels = 8;
  static const _minConfidence = 0.08;

  Interpreter? _interpreter;
  List<String> _labels = const [];
  bool _initFailed = false;

  bool get isAvailable => !kIsWeb && !_initFailed;

  Future<void> ensureInitialized() async {
    if (_interpreter != null || _initFailed) return;
    try {
      final labelsRaw = await rootBundle.loadString(_labelsAsset);
      _labels = labelsRaw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false);

      final interpreter = await Interpreter.fromAsset(_modelAsset);
      interpreter.allocateTensors();
      _interpreter = interpreter;
    } catch (_) {
      _initFailed = true;
    }
  }

  Future<List<String>> labelImage(Uint8List bytes) async {
    await ensureInitialized();
    final interpreter = _interpreter;
    if (interpreter == null || _labels.isEmpty) return const [];

    final decoded = img.decodeImage(bytes);
    if (decoded == null) return const [];

    final resized = img.copyResize(
      decoded,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          },
          growable: false,
        ),
        growable: false,
      ),
      growable: false,
    );

    final output = List.generate(
      1,
      (_) => List.filled(_labels.length, 0),
      growable: false,
    );

    interpreter.run(input, output);

    final scores = output[0];
    final ranked = <int, double>{};
    for (var i = 0; i < scores.length; i++) {
      ranked[i] = scores[i] / 255.0;
    }

    final top = ranked.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final labels = <String>[];
    for (final entry in top) {
      if (entry.value < _minConfidence) break;
      if (entry.key >= _labels.length) continue;
      final normalized = normalizeLabel(_labels[entry.key]);
      if (normalized.isEmpty || labels.contains(normalized)) continue;
      labels.add(normalized);
      if (labels.length >= _maxLabels) break;
    }
    return labels;
  }

  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }
}

String normalizeLabel(String label) => label.trim().toLowerCase();

List<String> mergeNormalizedLabels(Iterable<String> labels) {
  final merged = <String>[];
  for (final label in labels) {
    final normalized = normalizeLabel(label);
    if (normalized.isEmpty || merged.contains(normalized)) continue;
    merged.add(normalized);
  }
  return merged;
}
