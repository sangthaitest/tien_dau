import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const fontFamily = 'BeVietnamPro';

  static const bodyWeight = FontWeight.w400;
  static const metadataWeight = FontWeight.w500;
  static const titleWeight = FontWeight.w600;
  static const strongWeight = FontWeight.w700;

  static TextStyle money({
    required double size,
    required Color color,
    FontWeight weight = strongWeight,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.12,
      letterSpacing: -0.45,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
