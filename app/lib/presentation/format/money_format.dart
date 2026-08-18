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

/// V3 compact amounts for list summary / day totals (50k, 1.2tr).
String formatVndShort(int amount) {
  final abs = amount.abs();
  if (abs >= 1000000) {
    final tr = amount / 1000000;
    final text = tr.truncateToDouble() == tr
        ? tr.toStringAsFixed(0)
        : tr.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return '${text}tr';
  }
  if (abs >= 1000) {
    return '${(amount / 1000).round()}k';
  }
  return formatVnd(amount);
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
