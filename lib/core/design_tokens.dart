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
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEF3F2);
}

enum RcDesignStyle {
  materialExpressive,
  foruiMinimal,
  shadcnSaas,
  fieldDense,
}

extension RcDesignStyleX on RcDesignStyle {
  String get label => switch (this) {
        RcDesignStyle.materialExpressive => 'Material 3 Expressive',
        RcDesignStyle.foruiMinimal => 'Forui-inspired Minimal',
        RcDesignStyle.shadcnSaas => 'Shadcn-inspired SaaS',
        RcDesignStyle.fieldDense => 'Field Dense',
      };

  String get description => switch (this) {
        RcDesignStyle.materialExpressive =>
          'Expressive Material shapes, connected controls and stronger hierarchy.',
        RcDesignStyle.foruiMinimal =>
          'Quiet surfaces, generous whitespace and restrained utility controls.',
        RcDesignStyle.shadcnSaas =>
          'Crisp SaaS density, subtle borders and compact command surfaces.',
        RcDesignStyle.fieldDense =>
          'Maximum field information density while preserving touch targets.',
      };
}

abstract final class RcRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 24.0;
  static const xl = 30.0;
}

ThemeData buildRcTheme({
  bool highContrast = false,
  RcDesignStyle designStyle = RcDesignStyle.materialExpressive,
  Brightness brightness = Brightness.light,
}) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: RcColors.brand,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFFFFB3B8) : RcColors.brand,
    onPrimary: dark ? const Color(0xFF680014) : Colors.white,
    secondary: dark ? const Color(0xFFADC6FF) : RcColors.blue,
    error: dark ? const Color(0xFFFFB4AB) : RcColors.danger,
    surface: dark ? const Color(0xFF15191F) : RcColors.surface,
    surfaceContainerLowest:
        dark ? const Color(0xFF101317) : RcColors.surface,
    surfaceContainerLow:
        dark ? const Color(0xFF181C22) : RcColors.surface2,
    surfaceContainer:
        dark ? const Color(0xFF1D2229) : const Color(0xFFF1F4F8),
    outline: dark ? const Color(0xFF8B919A) : RcColors.lineStrong,
    outlineVariant: dark ? const Color(0xFF3F454D) : RcColors.line,
  );

  final radius = switch (designStyle) {
    RcDesignStyle.materialExpressive => RcRadius.lg,
    RcDesignStyle.foruiMinimal => 16.0,
    RcDesignStyle.shadcnSaas => 10.0,
    RcDesignStyle.fieldDense => 8.0,
  };
  final fieldRadius = switch (designStyle) {
    RcDesignStyle.materialExpressive => RcRadius.md,
    RcDesignStyle.foruiMinimal => 14.0,
    RcDesignStyle.shadcnSaas => 8.0,
    RcDesignStyle.fieldDense => 6.0,
  };
  final border = highContrast
      ? (dark ? Colors.white : RcColors.ink)
      : scheme.outlineVariant;

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF0F1216) : RcColors.bg,
    visualDensity: designStyle == RcDesignStyle.fieldDense
        ? VisualDensity.compact
        : VisualDensity.standard,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.7,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.35,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
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
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
        ),
        side: BorderSide(color: border),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
    ),
    navigationRailTheme: NavigationRailThemeData(
      elevation: 0,
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      useIndicator: true,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RcRadius.sm),
      ),
      side: BorderSide(color: border),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}
