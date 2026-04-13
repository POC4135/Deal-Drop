import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

final class DealDropPalette {
  static const cream = Color(0xFFFFFBF4);
  static const warmSurface = Color(0xFFF7EFE3);
  static const warmSurfaceStrong = Color(0xFFF0E2CF);
  static const ink = Color(0xFF1E1711);
  static const body = Color(0xFF5D5348);
  static const muted = Color(0xFFA79A8A);
  static const gold = Color(0xFFE4A521);
  static const goldDeep = Color(0xFFA96E00);
  static const goldSoft = Color(0xFFFFF0CC);
  static const mint = Color(0xFFA9F0EA);
  static const mintDeep = Color(0xFF0D7C78);
  static const rose = Color(0xFFF8D5D9);
  static const coral = Color(0xFFFFD8CB);
  static const sky = Color(0xFFD9EBFF);
  static const lilac = Color(0xFFE9DFFF);
  static const success = Color(0xFF2B9A66);
  static const warning = Color(0xFFE97E28);
  static const divider = Color(0xFFEADFCE);
  static const shadow = Color(0x12000000);
}

final class DealDropSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
}

final class DealDropRadii {
  static const sm = Radius.circular(14);
  static const md = Radius.circular(20);
  static const lg = Radius.circular(28);
  static const pill = Radius.circular(999);
}

final class DealDropShadows {
  static const card = [
    BoxShadow(
      color: DealDropPalette.shadow,
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];

  static const soft = [
    BoxShadow(
      color: DealDropPalette.shadow,
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
  ];
}

@immutable
class DealDropThemeTokens extends ThemeExtension<DealDropThemeTokens> {
  const DealDropThemeTokens({
    required this.screenPadding,
    required this.sectionGap,
    required this.cardRadius,
    required this.pillRadius,
  });

  final double screenPadding;
  final double sectionGap;
  final BorderRadius cardRadius;
  final BorderRadius pillRadius;

  @override
  DealDropThemeTokens copyWith({
    double? screenPadding,
    double? sectionGap,
    BorderRadius? cardRadius,
    BorderRadius? pillRadius,
  }) {
    return DealDropThemeTokens(
      screenPadding: screenPadding ?? this.screenPadding,
      sectionGap: sectionGap ?? this.sectionGap,
      cardRadius: cardRadius ?? this.cardRadius,
      pillRadius: pillRadius ?? this.pillRadius,
    );
  }

  @override
  DealDropThemeTokens lerp(
    ThemeExtension<DealDropThemeTokens>? other,
    double t,
  ) {
    if (other is! DealDropThemeTokens) {
      return this;
    }

    return DealDropThemeTokens(
      screenPadding: lerpDouble(screenPadding, other.screenPadding, t)!,
      sectionGap: lerpDouble(sectionGap, other.sectionGap, t)!,
      cardRadius: BorderRadius.lerp(cardRadius, other.cardRadius, t)!,
      pillRadius: BorderRadius.lerp(pillRadius, other.pillRadius, t)!,
    );
  }
}
