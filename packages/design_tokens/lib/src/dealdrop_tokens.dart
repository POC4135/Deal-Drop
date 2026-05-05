import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

final class DealDropPalette {
  static const cream = Color(0xFFFBFAF4);
  static const warmSurface = Color(0xFFEFF6ED);
  static const warmSurfaceStrong = Color(0xFFDCEBDC);
  static const ink = Color(0xFF17211B);
  static const body = Color(0xFF526159);
  static const muted = Color(0xFF829086);
  static const gold = Color(0xFFFF6B4A);
  static const goldDeep = Color(0xFFC23A22);
  static const goldSoft = Color(0xFFFFE8DF);
  static const mint = Color(0xFFC8F3CF);
  static const mintDeep = Color(0xFF167747);
  static const rose = Color(0xFFFFDCE4);
  static const coral = Color(0xFFFFDFD0);
  static const sky = Color(0xFFDCEEFE);
  static const lilac = Color(0xFFEDE4FF);
  static const success = Color(0xFF168A57);
  static const warning = Color(0xFFD96824);
  static const divider = Color(0xFFDCE8DD);
  static const shadow = Color(0x1A0A2015);
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
