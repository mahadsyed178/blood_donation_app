import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// One design system for every screen: spacing, radii, elevation, type
/// scale, and the Material theme that applies them app-wide so a plain
/// `ElevatedButton` / `Card` / `TextFormField` already looks right.

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Horizontal page gutter.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets card = EdgeInsets.all(lg);
}

class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 22;
  static const double pill = 999;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
}

class AppShadows {
  AppShadows._();

  /// Resting card.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Floating surfaces (bottom bars, sheets).
  static List<BoxShadow> get raised => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 14,
          offset: const Offset(0, -4),
        ),
      ];

  /// Primary call to action.
  static List<BoxShadow> get primary => [
        BoxShadow(
          color: AppColors.primaryRed.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ];
}

class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

class AppText {
  AppText._();
  static const TextStyle display = TextStyle(
      fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.1, color: AppColors.textDark);
  static const TextStyle h1 =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static const TextStyle h2 =
      TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static const TextStyle h3 =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark);
  static const TextStyle title =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark);
  static const TextStyle body =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark, height: 1.4);
  static const TextStyle bodySmall =
      TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: AppColors.textGrey, height: 1.35);
  static const TextStyle label =
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark);
  static const TextStyle caption =
      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textGrey);
  static const TextStyle overline = TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.textGrey);
  static const TextStyle button =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primaryRed,
    primary: AppColors.primaryRed,
    surface: Colors.white,
    error: AppColors.critical,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: AppRadius.lgAll,
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bgGrey,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      headlineMedium: AppText.h1,
      titleLarge: AppText.h2,
      titleMedium: AppText.title,
      bodyMedium: AppText.body,
      bodySmall: AppText.bodySmall,
      labelLarge: AppText.label,
      labelSmall: AppText.caption,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black12,
      centerTitle: false,
      titleTextStyle: AppText.h2,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(color: AppColors.borderGrey),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgGrey,
      hintStyle: const TextStyle(color: AppColors.hintGrey, fontSize: 13),
      errorStyle: const TextStyle(fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(AppColors.borderGrey),
      enabledBorder: border(AppColors.borderGrey),
      focusedBorder: border(AppColors.primaryRed, 1.5),
      errorBorder: border(AppColors.critical, 1.2),
      focusedErrorBorder: border(AppColors.critical, 1.5),
      prefixIconColor: AppColors.hintGrey,
      suffixIconColor: AppColors.hintGrey,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primaryRed.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        textStyle: AppText.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryRed,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryRed,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.successGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.bgGrey,
      selectedColor: AppColors.primaryRed,
      side: const BorderSide(color: AppColors.borderGrey),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      titleTextStyle: AppText.h2,
      contentTextStyle: AppText.body,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      showDragHandle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryRed,
      unselectedItemColor: AppColors.textGrey,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 10),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderGrey, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      dense: true,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.successGreen : null,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.primaryRed),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: AppColors.textDark, borderRadius: AppRadius.smAll),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}
