import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

ThemeData buildAppTheme() {
  final nunito = GoogleFonts.nunitoTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.bg,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: nunito.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
  );
}
