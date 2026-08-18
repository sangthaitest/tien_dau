import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

String formatVnd(int amount, {bool withSymbol = true}) {
  final abs = amount.abs();
  final digits = abs.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    if (i > 0 && fromEnd % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  if (!withSymbol) return buffer.toString();
  return '$buffer ₫';
}

String monthLabel(DateTime month) => 'Tháng ${month.month} · ${month.year}';

String greetingFor(DateTime now) {
  final hour = now.hour;
  if (hour < 12) return 'Chào buổi sáng';
  if (hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

TextStyle moneyStyle({
  required double size,
  Color color = Colors.white,
  FontWeight weight = FontWeight.w800,
}) {
  return GoogleFonts.sora(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.4,
  );
}
