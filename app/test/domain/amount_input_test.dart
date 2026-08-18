import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/domain/amount/amount_input.dart';

void main() {
  test('parses grouped and raw numeric input', () {
    expect(AmountInput.parse(''), 0);
    expect(AmountInput.parse('0'), 0);
    expect(AmountInput.parse('25000'), 25000);
    expect(AmountInput.parse('25.000'), 25000);
    expect(AmountInput.parse('100.000'), 100000);
  });

  test('formats Vietnamese grouping without currency symbol', () {
    expect(AmountInput.formatGrouped(0), '');
    expect(AmountInput.formatGrouped(10000), '10.000');
    expect(AmountInput.formatGrouped(200000), '200.000');
  });

  test('V3 shortcuts are 10k 20k 50k 100k 200k', () {
    expect(AmountInput.shortcuts, [10000, 20000, 50000, 100000, 200000]);
    expect(AmountInput.matchingShortcut(100000), 100000);
    expect(AmountInput.matchingShortcut(25000), isNull);
  });
}
