/// VND amount parsing/formatting and V3 shortcut values.
/// UI must call this instead of encoding rules in widgets.
class AmountInput {
  AmountInput._();

  static const shortcuts = [10000, 20000, 50000, 100000, 200000];

  static const shortcutLabels = ['10k', '20k', '50k', '100k', '200k'];

  static int parse(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.parse(digits);
  }

  /// Grouped digits only (no currency symbol). Empty when amount is not positive.
  static String formatGrouped(int amount) {
    if (amount <= 0) return '';
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      if (i > 0 && fromEnd % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  static bool isShortcut(int amount) => shortcuts.contains(amount);

  static int? matchingShortcut(int amount) {
    return isShortcut(amount) ? amount : null;
  }
}
