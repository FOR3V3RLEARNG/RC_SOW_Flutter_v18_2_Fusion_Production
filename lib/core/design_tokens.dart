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

enum RcDesignStyle { materialExpressive, foruiMinimal, shadcnSaas, fieldDense }

extension RcDesignStyleX on RcDesignStyle {
  String get label => switch (this) {
    RcDesignStyle.materialExpressive => 'Material 3 Expressive',
    RcDesignStyle.foruiMinimal => 'Forui-inspired Minimal',
    RcDesignStyle.shadcnSaas => 'Shadcn-inspired SaaS',
    RcDesignStyle.fieldDense => 'Field Dense',
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
}) {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: RcColors.brand,
        brightness: Brightness.light,
        surface: RcColors.surface,
      ).copyWith(
        primary: RcColors.brand,
        onPrimary: Colors.white,
        secondary: RcColors.blue,
        error: RcColors.danger,
      );

  final border = highContrast ? RcColors.ink : RcColors.lineStrong;
  final radius = switch (designStyle) {
    RcDesignStyle.materialExpressive => RcRadius.lg,
    RcDesignStyle.foruiMinimal => 16.0,
    RcDesignStyle.shadcnSaas => 10.0,
    RcDesignStyle.fieldDense => 8.0,
  };

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: RcColors.bg,
    fontFamily: null,
    visualDensity: designStyle == RcDesignStyle.fieldDense
        ? VisualDensity.compact
        : VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      backgroundColor: RcColors.surface,
      foregroundColor: RcColors.ink,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: RcColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RcRadius.sm),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(RcRadius.sm),
        borderSide: BorderSide(color: border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: RcColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: highContrast ? RcColors.ink : RcColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RcRadius.sm),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
