import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_typography.dart';

ThemeData buildAppTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final primary = dark ? const Color(0xFF3DDBA0) : const Color(0xFF00B67A);
  final yellow = dark ? const Color(0xFFFFD65A) : const Color(0xFFF6C945);
  final bg = dark ? const Color(0xFF0E1116) : const Color(0xFFF3F5F8);
  final card = dark ? const Color(0xFF1A1F28) : const Color(0xFFFFFFFF);
  final cardBorder = dark ? const Color(0xFF2A313D) : const Color(0xFFE8EBF0);
  final divider = dark ? const Color(0xFF2C3440) : const Color(0xFFE4E8EE);
  final text = dark ? const Color(0xFFF2F4F7) : const Color(0xFF1A1D26);
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: bg,
      ).copyWith(
        tertiary: yellow,
        onTertiary: const Color(0xFF007A52),
        surfaceContainerLow: dark
            ? const Color(0xFF151A22)
            : const Color(0xFFF8F9FB),
      );
  final baseTextTheme = ThemeData(useMaterial3: true, brightness: brightness)
      .textTheme
      .apply(
        fontFamily: AppTypography.fontFamily,
        bodyColor: text,
        displayColor: text,
      );
  final textTheme = baseTextTheme.copyWith(
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontWeight: AppTypography.strongWeight,
      letterSpacing: -0.8,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontWeight: AppTypography.strongWeight,
      letterSpacing: -0.7,
    ),
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontWeight: AppTypography.strongWeight,
      letterSpacing: -0.6,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontWeight: AppTypography.strongWeight,
      letterSpacing: -0.45,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontWeight: AppTypography.strongWeight,
      letterSpacing: -0.35,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontWeight: AppTypography.titleWeight,
      letterSpacing: -0.25,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontWeight: AppTypography.titleWeight,
      letterSpacing: -0.2,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontWeight: AppTypography.titleWeight,
      letterSpacing: -0.1,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontWeight: AppTypography.titleWeight,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontWeight: AppTypography.bodyWeight,
      height: 1.45,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontWeight: AppTypography.bodyWeight,
      height: 1.4,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontWeight: AppTypography.bodyWeight,
      height: 1.35,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontWeight: AppTypography.titleWeight,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontWeight: AppTypography.metadataWeight,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontWeight: AppTypography.metadataWeight,
    ),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    fontFamily: AppTypography.fontFamily,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cardBorder),
      ),
    ),
    dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.titleWeight,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontWeight: AppTypography.titleWeight,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 2,
      highlightElevation: 1,
      shape: CircleBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      elevation: 0,
      modalElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: textTheme.titleLarge,
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
  );
}
