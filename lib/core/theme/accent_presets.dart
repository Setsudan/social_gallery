import 'package:flutter/material.dart';

class AccentPreset {
  const AccentPreset({required this.label, required this.color});

  final String label;
  final Color color;
}

abstract final class AccentPresets {
  static const blue = AccentPreset(label: 'Blue', color: Color(0xFF0381FE));
  static const purple = AccentPreset(label: 'Purple', color: Color(0xFF8B5CF6));
  static const green = AccentPreset(label: 'Green', color: Color(0xFF22C55E));
  static const orange = AccentPreset(label: 'Orange', color: Color(0xFFF97316));
  static const red = AccentPreset(label: 'Red', color: Color(0xFFEF4444));
  static const pink = AccentPreset(label: 'Pink', color: Color(0xFFEC4899));
  static const teal = AccentPreset(label: 'Teal', color: Color(0xFF14B8A6));

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

  static String labelFor(Color color) {
    for (final preset in all) {
      if (preset.color.toARGB32() == color.toARGB32()) {
        return preset.label;
      }
    }
    return blue.label;
  }

  static bool isPreset(Color color) {
    return all.any((preset) => preset.color.toARGB32() == color.toARGB32());
  }
}
