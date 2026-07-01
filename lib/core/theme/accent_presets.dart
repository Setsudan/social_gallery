import 'package:flutter/material.dart';

enum AccentPresetId { blue, purple, green, orange, red, pink, teal }

class AccentPreset {
  const AccentPreset({required this.id, required this.color});

  final AccentPresetId id;
  final Color color;
}

abstract final class AccentPresets {
  static const blue = AccentPreset(
    id: AccentPresetId.blue,
    color: Color(0xFF0381FE),
  );
  static const purple = AccentPreset(
    id: AccentPresetId.purple,
    color: Color(0xFF8B5CF6),
  );
  static const green = AccentPreset(
    id: AccentPresetId.green,
    color: Color(0xFF22C55E),
  );
  static const orange = AccentPreset(
    id: AccentPresetId.orange,
    color: Color(0xFFF97316),
  );
  static const red = AccentPreset(
    id: AccentPresetId.red,
    color: Color(0xFFEF4444),
  );
  static const pink = AccentPreset(
    id: AccentPresetId.pink,
    color: Color(0xFFEC4899),
  );
  static const teal = AccentPreset(
    id: AccentPresetId.teal,
    color: Color(0xFF14B8A6),
  );

  static const List<AccentPreset> all = [
    blue,
    purple,
    green,
    orange,
    red,
    pink,
    teal,
  ];

  static const Color defaultColor = Color(0xFF0381FE);

  static Color resolve(int? storedArgb) {
    if (storedArgb == null) return defaultColor;
    final color = Color(storedArgb);
    for (final preset in all) {
      if (preset.color.toARGB32() == color.toARGB32()) {
        return preset.color;
      }
    }
    return defaultColor;
  }

  static AccentPresetId? idFor(Color color) {
    for (final preset in all) {
      if (preset.color.toARGB32() == color.toARGB32()) {
        return preset.id;
      }
    }
    return null;
  }

  static bool isPreset(Color color) {
    return all.any((preset) => preset.color.toARGB32() == color.toARGB32());
  }
}
