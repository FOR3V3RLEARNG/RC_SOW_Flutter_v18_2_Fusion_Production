import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

abstract final class RcColors {
  static const Color brand = Color(0xFFD32F2F);
  static const Color brandStrong = Color(0xFF9D1720);
  static const Color brandSoft = Color(0xFFFFE9E7);
  static const Color canvas = Color(0xFFFFF9F7);
  static const Color surfaceSecondary = Color(0xFFF7F0ED);
  static const Color success = Color(0xFF247A3C);
  static const Color successSoft = Color(0xFFE5F4E8);
  static const Color warning = Color(0xFFA45A00);
  static const Color warningSoft = Color(0xFFFFE9C5);
  static const Color info = Color(0xFF176B87);
  static const Color infoSoft = Color(0xFFDDF2F8);
  static const Color sky = Color(0xFF4F7893);
  static const Color skySoft = Color(0xFFE4F1F7);
  static const Color mint = Color(0xFF4E7462);
  static const Color mintSoft = Color(0xFFE2F1E8);
  static const Color plum = Color(0xFF77536C);
  static const Color plumSoft = Color(0xFFF4E8F0);
  static const Color sunshine = Color(0xFF8A6500);
  static const Color sunshineSoft = Color(0xFFFFF0C8);
  static const Color ink = Color(0xFF291D1D);
  static const Color outline = Color(0xFFE4D8D4);
}

abstract final class RcTheme {
  static ThemeData light({
    bool highContrast = false,
    bool reducedMotion = false,
  }) {
    final generated = ColorScheme.fromSeed(
      seedColor: RcColors.brand,
      brightness: Brightness.light,
    );
    final scheme = generated.copyWith(
      primary: highContrast ? const Color(0xFFB00012) : RcColors.brand,
      onPrimary: Colors.white,
      primaryContainer:
          highContrast ? const Color(0xFFFFDAD9) : RcColors.brandSoft,
      onPrimaryContainer: RcColors.brandStrong,
      secondary: RcColors.info,
      onSecondary: Colors.white,
      secondaryContainer: RcColors.infoSoft,
      onSecondaryContainer: const Color(0xFF073E50),
      tertiary: RcColors.mint,
      tertiaryContainer: RcColors.mintSoft,
      onTertiaryContainer: const Color(0xFF173C2D),
      surface: const Color(0xFFFFFBFA),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFFF4F1),
      surfaceContainer: const Color(0xFFFCEFEB),
      surfaceContainerHigh: const Color(0xFFF7EAE6),
      surfaceContainerHighest: const Color(0xFFF1E4E0),
      onSurface: RcColors.ink,
      onSurfaceVariant: const Color(0xFF675A57),
      outline: highContrast ? RcColors.ink : const Color(0xFF8E7771),
      outlineVariant: highContrast ? RcColors.ink : RcColors.outline,
      error: const Color(0xFFBA1A1A),
    );
    return _base(
      scheme,
      highContrast: highContrast,
      reducedMotion: reducedMotion,
    ).copyWith(
      scaffoldBackgroundColor: highContrast ? Colors.white : RcColors.canvas,
    );
  }

  static ThemeData dark({
    bool highContrast = false,
    bool reducedMotion = false,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF6267),
      brightness: Brightness.dark,
      primary: const Color(0xFFFF6569),
      onPrimary: const Color(0xFF5B0009),
      primaryContainer: const Color(0xFF5C1E22),
      onPrimaryContainer: const Color(0xFFFFDAD9),
      secondary: const Color(0xFF85C7E1),
      onSecondary: const Color(0xFF003548),
      secondaryContainer: const Color(0xFF16384F),
      onSecondaryContainer: const Color(0xFFC4E8F8),
      tertiary: const Color(0xFF9ED5B7),
      onTertiary: const Color(0xFF073821),
      tertiaryContainer: const Color(0xFF173E2D),
      onTertiaryContainer: const Color(0xFFB9F1D1),
      surface: const Color(0xFF211A1A),
      surfaceContainerLowest: const Color(0xFF120D0D),
      surfaceContainerLow: const Color(0xFF211A1A),
      surfaceContainer: const Color(0xFF282020),
      surfaceContainerHigh: const Color(0xFF332929),
      surfaceContainerHighest: const Color(0xFF3E3232),
      onSurface: const Color(0xFFF4DEDC),
      onSurfaceVariant: const Color(0xFFD8C1BE),
      outline: const Color(0xFFA98C87),
      outlineVariant: const Color(0xFF584441),
      error: const Color(0xFFFFB4AB),
    );
    return _base(
      scheme,
      highContrast: highContrast,
      reducedMotion: reducedMotion,
    ).copyWith(scaffoldBackgroundColor: const Color(0xFF171212));
  }

  static ThemeData _base(
    ColorScheme scheme, {
    required bool highContrast,
    required bool reducedMotion,
  }) {
    final borderColor = highContrast
        ? scheme.onSurface
        : scheme.brightness == Brightness.dark
            ? scheme.outlineVariant
            : RcColors.outline;
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
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(52, 56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(52, 56),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(52, 56),
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(48, 48)),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.onSecondaryContainer,
        shape: const StadiumBorder(),
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(48, 48)),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            TextStyle(fontWeight: FontWeight.w800),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
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
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        minWidth: 76,
        minExtendedWidth: 230,
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w900),
        unselectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarThemeData(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        toolbarHeight: 68,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minTileHeight: 58,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        iconColor: scheme.onSurfaceVariant,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primaryContainer,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withOpacity(.12),
        valueIndicatorColor: scheme.inverseSurface,
        valueIndicatorTextStyle: TextStyle(color: scheme.onInverseSurface),
        trackHeight: 6,
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStatePropertyAll<Color>(scheme.outlineVariant),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll<Color>(scheme.onPrimary),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        showDuration: const Duration(seconds: 3),
        textStyle: TextStyle(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: reducedMotion
              ? const _NoPageTransitionsBuilder()
              : const PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: reducedMotion
              ? const _NoPageTransitionsBuilder()
              : const CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: reducedMotion
              ? const _NoPageTransitionsBuilder()
              : const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: reducedMotion
              ? const _NoPageTransitionsBuilder()
              : const CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: reducedMotion
              ? const _NoPageTransitionsBuilder()
              : const FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}
