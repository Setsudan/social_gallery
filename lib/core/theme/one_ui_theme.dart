import 'package:flutter/material.dart';
import 'package:social_gallery/core/animation/page_transitions.dart';

/// Samsung One UI design tokens and [ThemeData] builders.
abstract final class OneUiColors {
  static const accent = Color(0xFF0381FE);

  static const lightBackground = Color(0xFFF2F2F2);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF010101);
  static const lightOnSurfaceVariant = Color(0xFF5E5E5E);
  static const lightOutline = Color(0xFFE0E0E0);

  static const darkBackground = Color(0xFF010101);
  static const darkSurface = Color(0xFF171717);
  static const darkSurfaceHigh = Color(0xFF252525);
  static const darkOnSurface = Color(0xFFF2F2F2);
  static const darkOnSurfaceVariant = Color(0xFF9E9E9E);
  static const darkOutline = Color(0xFF3A3A3A);
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
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final bg = isLight
        ? OneUiColors.lightBackground
        : OneUiColors.darkBackground;
    final surface = isLight
        ? OneUiColors.lightSurface
        : OneUiColors.darkSurface;
    final onSurface = isLight
        ? OneUiColors.lightOnSurface
        : OneUiColors.darkOnSurface;
    final onVariant = isLight
        ? OneUiColors.lightOnSurfaceVariant
        : OneUiColors.darkOnSurfaceVariant;
    final outline = isLight
        ? OneUiColors.lightOutline
        : OneUiColors.darkOutline;
    final surfaceContainer = isLight
        ? const Color(0xFFEBEBEB)
        : OneUiColors.darkSurfaceHigh;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: OneUiColors.accent,
      onPrimary: Colors.white,
      primaryContainer: OneUiColors.accent.withValues(alpha: 0.12),
      onPrimaryContainer: OneUiColors.accent,
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
      brightness: brightness,
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
        indicatorColor: OneUiColors.accent.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? OneUiColors.accent : onVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? OneUiColors.accent : onVariant,
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
          borderSide: const BorderSide(color: OneUiColors.accent, width: 2),
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
        selectedColor: OneUiColors.accent.withValues(alpha: 0.14),
        labelStyle: textTheme.bodyMedium!,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.chip),
        ),
        side: BorderSide.none,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: OneUiColors.accent,
        thumbColor: OneUiColors.accent,
        overlayColor: OneUiColors.accent.withValues(alpha: 0.12),
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
            return OneUiColors.accent;
          }
          return surfaceContainer;
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: OneUiColors.accent,
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
          foregroundColor: OneUiColors.accent,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: OneUiColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OneUiRadii.pill),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: OneUiColors.accent,
      ),
      iconTheme: IconThemeData(color: onSurface, size: 24),
      pageTransitionsTheme: oneUiPageTransitionsTheme,
      extensions: const [OneUiThemeExtension()],
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
  const OneUiThemeExtension();

  Color pageBackground(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.light
        ? OneUiColors.lightBackground
        : OneUiColors.darkBackground;
  }

  Color groupedSurface(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  @override
  OneUiThemeExtension copyWith() => this;

  @override
  OneUiThemeExtension lerp(
    ThemeExtension<OneUiThemeExtension>? other,
    double t,
  ) => this;
}

extension OneUiThemeContext on BuildContext {
  OneUiThemeExtension get oneUi =>
      Theme.of(this).extension<OneUiThemeExtension>() ??
      const OneUiThemeExtension();
}
