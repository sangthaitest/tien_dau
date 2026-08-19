import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final primary = dark ? const Color(0xFF3DDBA0) : const Color(0xFF00B67A);
  final bg = dark ? const Color(0xFF0E1116) : const Color(0xFFF3F5F8);
  final text = dark ? const Color(0xFFF2F4F7) : const Color(0xFF1A1D26);
  final nunito = GoogleFonts.nunitoTextTheme();
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surface: bg,
    ),
    scaffoldBackgroundColor: bg,
    textTheme: nunito.apply(bodyColor: text, displayColor: text),
    appBarTheme: AppBarTheme(
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
  );
}
