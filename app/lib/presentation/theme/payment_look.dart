import 'package:flutter/material.dart';

import '../../domain/entities/payment_method_kind.dart';
import 'app_colors.dart';

class PaymentLook {
  const PaymentLook({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}

const _cashColor = Color(0xFF00B67A);
const _cashBackground = Color(0xFFE6F8EF);
const _cardColor = Color(0xFF2F80ED);
const _cardBackground = Color(0xFFE8F2FF);
const _momoColor = Color(0xFF7B4DFF);
const _momoBackground = Color(0xFFF1EAFF);

const _palette = <Color>[
  Color(0xFFFF8A5B),
  Color(0xFF2BBBAD),
  Color(0xFFFF6B9D),
  Color(0xFFEF6C00),
  Color(0xFF5C6BC0),
  Color(0xFF00838F),
  Color(0xFFA0785A),
  Color(0xFF6B7C93),
  Color(0xFFD81B60),
  Color(0xFF43A047),
];

PaymentLook paymentLook({
  required String sourceId,
  required String name,
  required PaymentMethodKind method,
}) {
  final folded = _fold(name);
  final color = _colorFor(folded: folded, sourceId: sourceId, method: method);
  return PaymentLook(
    icon: _iconFor(method),
    color: color,
    background: _backgroundFor(folded, color),
  );
}

Color _colorFor({
  required String folded,
  required String sourceId,
  required PaymentMethodKind method,
}) {
  if (folded.isEmpty || folded == 'chua co phuong thuc') {
    return AppColors.textTertiary;
  }
  if (folded == 'tien mat') return _cashColor;
  if (folded.contains('momo')) return _momoColor;
  if (folded == 'the ngan hang') return _cardColor;
  final index = _stableIndex('$sourceId\u0000$folded\u0000${method.name}');
  return _palette[index];
}

Color _backgroundFor(String folded, Color color) {
  if (folded.isEmpty || folded == 'chua co phuong thuc') {
    return AppColors.surfaceVariant;
  }
  if (folded == 'tien mat') return _cashBackground;
  if (folded.contains('momo')) return _momoBackground;
  if (folded == 'the ngan hang') return _cardBackground;
  return color.withValues(alpha: AppColors.dark ? 0.22 : 0.14);
}

IconData _iconFor(PaymentMethodKind method) {
  return switch (method) {
    PaymentMethodKind.cash => Icons.payments_outlined,
    PaymentMethodKind.bankAccount => Icons.account_balance_outlined,
    PaymentMethodKind.eWallet => Icons.account_balance_wallet_outlined,
    PaymentMethodKind.creditCard ||
    PaymentMethodKind.debitCard => Icons.credit_card_outlined,
    PaymentMethodKind.other => Icons.more_horiz,
  };
}

int _stableIndex(String key) {
  var hash = 0;
  for (final unit in key.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return hash % _palette.length;
}

String _fold(String value) {
  const pairs = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };
  final buffer = StringBuffer();
  for (final rune in value.trim().toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(pairs[char] ?? char);
  }
  return buffer.toString();
}
