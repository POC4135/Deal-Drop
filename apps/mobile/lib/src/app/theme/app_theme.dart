import 'package:dealdrop_design_tokens/dealdrop_design_tokens.dart';
import 'package:flutter/material.dart';

ThemeData buildDealDropTheme() {
  const colorScheme = ColorScheme.light(
    primary: DealDropPalette.gold,
    secondary: DealDropPalette.mint,
    surface: DealDropPalette.cream,
    onPrimary: Colors.white,
    onSecondary: DealDropPalette.ink,
    onSurface: DealDropPalette.ink,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: DealDropPalette.cream,
    dividerColor: DealDropPalette.divider,
    cardColor: Colors.white,
  );

  final textTheme = base.textTheme.copyWith(
    displayLarge: const TextStyle(
      fontFamily: 'Georgia',
      fontSize: 48,
      height: 1.0,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    displayMedium: const TextStyle(
      fontFamily: 'Georgia',
      fontSize: 36,
      height: 1.05,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    headlineLarge: const TextStyle(
      fontFamily: 'Georgia',
      fontSize: 28,
      height: 1.15,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    headlineMedium: const TextStyle(
      fontFamily: 'Georgia',
      fontSize: 24,
      height: 1.18,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    titleLarge: const TextStyle(
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    titleMedium: const TextStyle(
      fontSize: 18,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    bodyLarge: const TextStyle(
      fontSize: 18,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: DealDropPalette.body,
    ),
    bodyMedium: const TextStyle(
      fontSize: 16,
      height: 1.5,
      fontWeight: FontWeight.w500,
      color: DealDropPalette.body,
    ),
    bodySmall: const TextStyle(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w500,
      color: DealDropPalette.muted,
    ),
    labelLarge: const TextStyle(
      fontSize: 15,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
      color: DealDropPalette.ink,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      color: DealDropPalette.body,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DealDropSpacing.md,
        vertical: DealDropSpacing.md,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: DealDropPalette.muted),
      prefixIconColor: DealDropPalette.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: DealDropPalette.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: DealDropPalette.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: DealDropPalette.goldDeep, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DealDropPalette.gold,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(64),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DealDropPalette.ink,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(64),
        side: const BorderSide(color: DealDropPalette.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: textTheme.titleMedium,
      ),
    ),
    extensions: const [
      DealDropThemeTokens(
        screenPadding: 20,
        sectionGap: 24,
        cardRadius: BorderRadius.all(DealDropRadii.md),
        pillRadius: BorderRadius.all(DealDropRadii.pill),
      ),
    ],
  );
}

extension DealDropThemeContext on BuildContext {
  DealDropThemeTokens get tokens =>
      Theme.of(this).extension<DealDropThemeTokens>()!;
}
