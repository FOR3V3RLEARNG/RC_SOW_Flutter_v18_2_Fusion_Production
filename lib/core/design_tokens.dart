import 'app_constants.dart';
import 'package:flutter/material.dart';

abstract final class RcColors {
  static const brand = Color(0xFFC91F2C);
  static const brandDeep = Color(0xFF971621);
  static const brandSoft = Color(0xFFFFF1F2);
  static const ink = Color(0xFF101828);
  static const text = Color(0xFF344054);
  static const muted = Color(0xFF667085);
  static const bg = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const surface2 = Color(0xFFF8FAFC);
  static const line = Color(0xFFE4E7EC);
  static const lineStrong = Color(0xFFD0D5DD);
  static const success = Color(0xFF12805C);
  static const successSoft = Color(0xFFECFDF3);
  static const warning = Color(0xFFB54708);
  static const warningSoft = Color(0xFFFFFAEB);
  static const blue = Color(0xFF175CD3);
  static const blueSoft = Color(0xFFEFF8FF);
  static const purple = Color(0xFF6941C6);
  static const purpleSoft = Color(0xFFF4F3FF);
  static const teal = Color(0xFF087E8B);
  static const tealSoft = Color(0xFFEAFBFC);
  static const gold = Color(0xFF9A6700);
  static const goldSoft = Color(0xFFFFF7D6);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEF3F2);
}

abstract final class RcRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 30.0;
  static const hero = 36.0;
}

abstract final class RcSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

/// v18.2 visual density contract: generous breathing room with restrained icon scale.
abstract final class RcIconSize {
  static const xs = 14.0;
  static const sm = 18.0;
  static const md = 20.0;
  static const lg = 22.0;
  static const hero = 28.0;
}

abstract final class RcLayout {
  static const pageHorizontal = 16.0;
  static const pageTop = 18.0;
  static const sectionGap = 20.0;
  static const cardPadding = 16.0;
  static const cardGap = 12.0;
  static const maxContentWidth = 1320.0;
}

abstract final class RcMotion {
  static const quick = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const deliberate = Duration(milliseconds: 420);
  static const expressiveCurve = Curves.easeOutCubic;
}

ThemeData buildRcTheme({
  bool highContrast = false,
  bool compactDensity = false,
  Brightness brightness = Brightness.light,
  RcDesignDna designDna = RcDesignDna.redCrossClassic,
}) {
  final dark = brightness == Brightness.dark || designDna.prefersDark;
  final effectiveBrightness = dark ? Brightness.dark : brightness;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: designDna.seed,
        brightness: effectiveBrightness,
      ).copyWith(
        primary: dark
            ? ColorScheme.fromSeed(
                seedColor: designDna.seed,
                brightness: Brightness.dark,
              ).primary
            : designDna.seed,
        onPrimary: dark ? const Color(0xFF680014) : Colors.white,
        secondary: dark ? const Color(0xFFADC6FF) : RcColors.blue,
        error: dark ? const Color(0xFFFFB4AB) : RcColors.danger,
        surface: dark ? const Color(0xFF15191F) : RcColors.surface,
        surfaceContainerLowest: dark
            ? const Color(0xFF101317)
            : RcColors.surface,
        surfaceContainerLow: dark ? const Color(0xFF181C22) : RcColors.surface2,
        surfaceContainer: dark
            ? const Color(0xFF1D2229)
            : const Color(0xFFF1F4F8),
        outline: dark ? const Color(0xFF8B919A) : RcColors.lineStrong,
        outlineVariant: dark ? const Color(0xFF3F454D) : RcColors.line,
      );

  final border = highContrast
      ? (dark ? Colors.white : RcColors.ink)
      : scheme.outlineVariant;

  final base = ThemeData(
    useMaterial3: true,
    brightness: effectiveBrightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0F1216) : RcColors.bg,
    visualDensity: compactDensity
        ? VisualDensity.compact
        : VisualDensity.standard,
    iconTheme: IconThemeData(
      size: RcIconSize.md,
      color: scheme.onSurfaceVariant,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        iconSize: RcIconSize.md,
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
        height: 1.05,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.7,
        height: 1.10,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.45,
        height: 1.12,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.35,
        height: 1.18,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        height: 1.22,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 16.5,
        fontWeight: FontWeight.w600,
        height: 1.45,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.42,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.38,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        letterSpacing: .05,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RcRadius.md),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RcRadius.md),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RcRadius.md),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: .78),
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RcRadius.lg),
        side: BorderSide(color: border),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w900
              : FontWeight.w700,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      elevation: 0,
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      useIndicator: true,
      selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w900),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primaryContainer;
          }
          if (states.contains(WidgetState.pressed)) {
            return scheme.surfaceContainer;
          }
          return scheme.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: .38);
          }
          return states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurface;
        }),
        overlayColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: .08),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(52, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: .1,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(52, 54),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
        side: BorderSide(color: border, width: 1.35),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(52, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        elevation: 1,
        shadowColor: scheme.shadow.withValues(alpha: .14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 2,
      highlightElevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      extendedTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: scheme.onInverseSurface,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RcRadius.sm),
      ),
      side: BorderSide(color: border),
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}
