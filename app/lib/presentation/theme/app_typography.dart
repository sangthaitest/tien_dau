import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const fontFamily = 'BeVietnamPro';

  static const bodyWeight = FontWeight.w400;
  static const metadataWeight = FontWeight.w500;
  static const titleWeight = FontWeight.w600;
  static const strongWeight = FontWeight.w700;
  static const extraWeight = FontWeight.w800;

  static const buttonSize = 16.0;
  static const dialogTitleSize = 18.0;
  static const screenTitleSize = 22.0;

  static TextStyle button({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: buttonSize,
      fontWeight: extraWeight,
      height: 1.2,
      letterSpacing: -0.1,
      color: color,
    );
  }

  static TextStyle buttonSecondary({Color? color}) {
    return button(color: color);
  }

  static TextStyle screenTitle({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: screenTitleSize,
      fontWeight: extraWeight,
      height: 1.2,
      letterSpacing: -0.4,
      color: color,
    );
  }

  static TextStyle dialogTitle({Color? color}) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: dialogTitleSize,
      fontWeight: extraWeight,
      height: 1.25,
      letterSpacing: -0.25,
      color: color,
    );
  }

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
