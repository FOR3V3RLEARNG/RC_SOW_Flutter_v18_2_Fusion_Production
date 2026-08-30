import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class RcColors {
  static const Color brand = Color(0xFFD9292F);
  static const Color brandStrong = Color(0xFF9F111B);
  static const Color brandSoft = Color(0xFFFFE9E8);
  static const Color canvas = Color(0xFFF7F5F3);
  static const Color surfaceSecondary = Color(0xFFF2EFEC);
  static const Color success = Color(0xFF247A3C);
  static const Color successSoft = Color(0xFFE2F3E6);
  static const Color warning = Color(0xFFA76300);
  static const Color warningSoft = Color(0xFFFFEAC1);
  static const Color info = Color(0xFF1769AA);
  static const Color infoSoft = Color(0xFFE1F0FB);
  static const Color ink = Color(0xFF241D1D);
  static const Color outline = Color(0xFFE0D8D4);
}

abstract final class RcTheme {
  static ThemeData light({bool highContrast = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: RcColors.brand,
      brightness: Brightness.light,
      primary: highContrast ? const Color(0xFFB00012) : RcColors.brand,
      surface: Colors.white,
      error: const Color(0xFFBA1A1A),
    );
    return _base(scheme, highContrast: highContrast).copyWith(
      scaffoldBackgroundColor: highContrast ? Colors.white : RcColors.canvas,
    );
  }

  static ThemeData dark({bool highContrast = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6267),
      brightness: Brightness.dark,
      primary: const Color(0xFFFF6569),
      surface: const Color(0xFF211A1A),
      error: const Color(0xFFFFB4AB),
    );
    return _base(
      scheme,
      highContrast: highContrast,
    ).copyWith(scaffoldBackgroundColor: const Color(0xFF171212));
  }

  static ThemeData _base(ColorScheme scheme, {required bool highContrast}) {
    final borderColor = highContrast ? scheme.onSurface : scheme.outlineVariant;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(fontSize: 16, height: 1.42),
        bodyMedium: TextStyle(fontSize: 14, height: 1.42),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: .1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
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
      appBarTheme: AppBarThemeData(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
