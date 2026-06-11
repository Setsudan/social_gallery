import 'package:flutter/material.dart';
import 'package:social_gallery/core/animation/page_transitions.dart';
import 'package:social_gallery/core/theme/app_theme_variant.dart';

/// Samsung One UI design tokens and [ThemeData] builders.
class AppThemePalette {
  const AppThemePalette({
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.brightness,
  });

  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Brightness brightness;

  static AppThemePalette forVariant(AppThemeVariant variant) {
    return switch (variant) {
      AppThemeVariant.light => const AppThemePalette(
        background: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        surfaceContainer: Color(0xFFF0F0F0),
        onSurface: Color(0xFF010101),
        onSurfaceVariant: Color(0xFF5E5E5E),
        outline: Color(0xFFE0E0E0),
        brightness: Brightness.light,
      ),
      AppThemeVariant.solar => const AppThemePalette(
        background: Color(0xFFF5ECD7),
        surface: Color(0xFFFAF6EC),
        surfaceContainer: Color(0xFFEDE4CF),
        onSurface: Color(0xFF2C2416),
        onSurfaceVariant: Color(0xFF6B5D48),
        outline: Color(0xFFD9CEB8),
        brightness: Brightness.light,
      ),
      AppThemeVariant.dark => const AppThemePalette(
        background: Color(0xFF1A1A1A),
        surface: Color(0xFF242424),
        surfaceContainer: Color(0xFF2E2E2E),
        onSurface: Color(0xFFF2F2F2),
        onSurfaceVariant: Color(0xFF9E9E9E),
        outline: Color(0xFF3A3A3A),
        brightness: Brightness.dark,
      ),
      AppThemeVariant.darkOled => const AppThemePalette(
        background: Color(0xFF000000),
        surface: Color(0xFF0A0A0A),
        surfaceContainer: Color(0xFF141414),
        onSurface: Color(0xFFF2F2F2),
        onSurfaceVariant: Color(0xFF9E9E9E),
        outline: Color(0xFF2A2A2A),
        brightness: Brightness.dark,
      ),
      AppThemeVariant.system => forVariant(AppThemeVariant.light),
    };
  }
}

abstract final class OneUiSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double pageHorizontal = 20;
  static const double pageTop = 12;
  static const double sectionGap = 16;
  static const double listItemVertical = 14;
}

abstract final class OneUiRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 28;
  static const double sheet = 24;
  static const double dialog = 20;
  static const double card = 20;
  static const double chip = 20;
  static const double button = 26;
}

abstract final class OneUiTheme {
  static ThemeData build({
    required AppThemeVariant variant,
    required Color accent,
  }) {
    final palette = AppThemePalette.forVariant(variant);
    final isLight = palette.brightness == Brightness.light;
    final bg = palette.background;
    final surface = palette.surface;
    final onSurface = palette.onSurface;
    final onVariant = palette.onSurfaceVariant;
    final outline = palette.outline;
    final surfaceContainer = palette.surfaceContainer;

    final scheme = ColorScheme(
      brightness: palette.brightness,
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accent.withValues(alpha: 0.12),
      onPrimaryContainer: accent,
      secondary: onVariant,
      onSecondary: onSurface,
      secondaryContainer: surfaceContainer,
      onSecondaryContainer: onSurface,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainer,
      onSurfaceVariant: onVariant,
      outline: outline,
      outlineVariant: outline,
      error: const Color(0xFFEB5A46),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD4),
      onErrorContainer: const Color(0xFF410002),
    );

    final textTheme = _textTheme(onSurface, onVariant);

    return ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: onSurface, size: 24),
        actionsIconTheme: IconThemeData(color: onSurface, size: 24),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.card),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OneUiSpacing.md,
          vertical: OneUiSpacing.xs,
        ),
        iconColor: onVariant,
        titleTextStyle: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: onVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.md),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 64,
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? accent : onVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? accent : onVariant,
            size: 24,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: onVariant.withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(OneUiRadii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.dialog),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? const Color(0xFF323232) : surfaceContainer,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.white : onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.md),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: OneUiSpacing.md,
          vertical: OneUiSpacing.md,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: onVariant),
        hintStyle: textTheme.bodyMedium?.copyWith(color: onVariant),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(surfaceContainer),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OneUiRadii.pill),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: OneUiSpacing.md),
        ),
        textStyle: WidgetStateProperty.all(textTheme.bodyLarge),
        hintStyle: WidgetStateProperty.all(
          textTheme.bodyLarge?.copyWith(color: onVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: accent.withValues(alpha: 0.14),
        labelStyle: textTheme.bodyMedium!,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.chip),
        ),
        side: BorderSide.none,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
        inactiveTrackColor: outline,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent;
          }
          return surfaceContainer;
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: OneUiSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OneUiRadii.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(
            horizontal: OneUiSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OneUiRadii.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.pill),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      iconTheme: IconThemeData(color: onSurface, size: 24),
      pageTransitionsTheme: oneUiPageTransitionsTheme,
      extensions: [OneUiThemeExtension(pageBackground: bg)],
    );
  }

  static TextTheme _textTheme(Color onSurface, Color onVariant) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onVariant,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: onVariant,
      ),
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: onVariant,
      ),
    );
  }
}

/// Access One UI tokens from [Theme.of(context).extension].
class OneUiThemeExtension extends ThemeExtension<OneUiThemeExtension> {
  const OneUiThemeExtension({required this.pageBackground});

  final Color pageBackground;

  Color groupedSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  @override
  OneUiThemeExtension copyWith({Color? pageBackground}) {
    return OneUiThemeExtension(
      pageBackground: pageBackground ?? this.pageBackground,
    );
  }

  @override
  OneUiThemeExtension lerp(
    ThemeExtension<OneUiThemeExtension>? other,
    double t,
  ) {
    if (other is! OneUiThemeExtension) return this;
    return OneUiThemeExtension(
      pageBackground: Color.lerp(pageBackground, other.pageBackground, t)!,
    );
  }
}

extension OneUiThemeContext on BuildContext {
  OneUiThemeExtension get oneUi =>
      Theme.of(this).extension<OneUiThemeExtension>() ??
      const OneUiThemeExtension(pageBackground: Color(0xFFFFFFFF));
}
