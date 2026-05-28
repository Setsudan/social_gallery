import 'package:flutter/services.dart';

class AppHaptics {
  /// A very light tap for common button clicks and navigation.
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// A medium impact for selections, state toggles, and switches.
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// A selection click for tick adjustments.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// A double-pulse or heavy impact for deletions and success.
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// A specific success vibe sequence.
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }
}
