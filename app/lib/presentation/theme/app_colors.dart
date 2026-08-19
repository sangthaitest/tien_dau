import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool dark = false;

  static Color get primary =>
      dark ? const Color(0xFF3DDBA0) : const Color(0xFF00B67A);
  static Color get primaryDark =>
      dark ? const Color(0xFF7BD3C0) : const Color(0xFF009963);
  static Color get primaryDeep => const Color(0xFF00855A);
  static Color get primaryContainer =>
      dark ? const Color(0xFF0F2E24) : const Color(0xFFE6F8EF);
  static Color get bg =>
      dark ? const Color(0xFF0E1116) : const Color(0xFFF3F5F8);
  static Color get surfaceVariant =>
      dark ? const Color(0xFF242A35) : const Color(0xFFEEF1F5);
  static Color get card =>
      dark ? const Color(0xFF1A1F28) : const Color(0xFFFFFFFF);
  static Color get text =>
      dark ? const Color(0xFFF2F4F7) : const Color(0xFF1A1D26);
  static Color get textSecondary =>
      dark ? const Color(0xFFA0A8B4) : const Color(0xFF5C6470);
  static Color get textTertiary =>
      dark ? const Color(0xFF6B7482) : const Color(0xFF8B93A0);
  static Color get expense =>
      dark ? const Color(0xFFFF8A8A) : const Color(0xFFFF6B6B);
  static Color get expenseContainer =>
      dark ? const Color(0xFF3A1C1C) : const Color(0xFFFFECEC);
  static Color get income =>
      dark ? const Color(0xFF4ECDC4) : const Color(0xFF00A3A1);
  static Color get incomeContainer =>
      dark ? const Color(0xFF0D2E2C) : const Color(0xFFE0F7F5);
  static Color get warning =>
      dark ? const Color(0xFFFFC857) : const Color(0xFFFFB020);
  static Color get warningContainer =>
      dark ? const Color(0xFF3A2E12) : const Color(0xFFFFF6E5);
  static Color get divider =>
      dark ? const Color(0xFF2C3440) : const Color(0xFFE4E8EE);
  static Color get onPrimary =>
      dark ? const Color(0xFF0A1A14) : const Color(0xFFFFFFFF);
  static Color get navBar =>
      dark ? const Color(0xF01A1F28) : const Color(0xEBFFFFFF);
}
