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
      fontSize: 42,
      height: 1.02,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    displayMedium: const TextStyle(
      fontFamily: 'Georgia',
      fontSize: 30,
      height: 1.08,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    headlineLarge: const TextStyle(
      fontFamily: 'Georgia',
      fontSize: 24,
      height: 1.15,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    headlineMedium: const TextStyle(
      fontFamily: 'Georgia',
      fontSize: 21,
      height: 1.18,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    titleLarge: const TextStyle(
      fontSize: 19,
      height: 1.2,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: DealDropPalette.ink,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      height: 1.42,
      fontWeight: FontWeight.w500,
      color: DealDropPalette.body,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      height: 1.42,
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
      letterSpacing: 0,
      color: DealDropPalette.ink,
    ),
    labelMedium: const TextStyle(
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
      color: DealDropPalette.body,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: DealDropPalette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      disabledColor: DealDropPalette.divider,
      selectedColor: DealDropPalette.gold,
      secondarySelectedColor: DealDropPalette.gold,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: textTheme.labelLarge!,
      secondaryLabelStyle: textTheme.labelLarge!.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(
          color: DealDropPalette.goldDeep,
          width: 1.5,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: DealDropPalette.ink,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DealDropPalette.gold,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.titleMedium?.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DealDropPalette.ink,
        backgroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: DealDropPalette.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.titleMedium,
      ),
    ),
    extensions: const [
      DealDropThemeTokens(
        screenPadding: 20,
        sectionGap: 22,
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
