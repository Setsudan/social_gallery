import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_gallery/app/providers.dart';

/// Scales animation timing from user settings and system accessibility.
class AppMotion {
  AppMotion({required this.speedFactor, this.systemAnimationsDisabled = false});

  final double speedFactor;
  final bool systemAnimationsDisabled;

  static const double disabledSpeed = 0.001;

  factory AppMotion.of(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return AppMotion(
      speedFactor: settings.animationSpeed,
      systemAnimationsDisabled: MediaQuery.disableAnimationsOf(context),
    );
  }

  factory AppMotion.read(BuildContext context, Ref ref) {
    final settings = ref.read(settingsProvider);
    return AppMotion(
      speedFactor: settings.animationSpeed,
      systemAnimationsDisabled: MediaQuery.disableAnimationsOf(context),
    );
  }

  factory AppMotion.fromSettings(
    AppSettings settings, {
    bool systemAnimationsDisabled = false,
  }) {
    return AppMotion(
      speedFactor: settings.animationSpeed,
      systemAnimationsDisabled: systemAnimationsDisabled,
    );
  }

  bool get enabled =>
      !systemAnimationsDisabled && speedFactor > disabledSpeed * 2;

  Duration duration(int baseMs) {
    if (!enabled) return Duration.zero;
    final ms = (baseMs * speedFactor).round();
    return Duration(milliseconds: ms < 1 ? 1 : ms);
  }

  Duration get fadeFast => duration(150);
  Duration get fade => duration(250);
  Duration get transition => duration(350);
  Duration get staggerStep => duration(40);

  Curve get enterCurve => Curves.easeOutCubic;
  Curve get exitCurve => Curves.easeInCubic;

  /// Max items to animate on first paint (performance cap).
  static const int maxStaggerItems = 24;
}
