import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/presentation/format/money_format.dart';

void main() {
  test('formats VND with grouping dots', () {
    expect(formatVnd(0), '0 ₫');
    expect(formatVnd(25000), '25.000 ₫');
    expect(formatVnd(18500000), '18.500.000 ₫');
  });

  test('formats compact VND like V3 summaries', () {
    expect(formatVndShort(0), '0 ₫');
    expect(formatVndShort(50000), '50k');
    expect(formatVndShort(1000000), '1tr');
  });

  test('privacy mask matches Demo dots', () {
    expect(displayVnd(25000, hidden: false), '25.000 ₫');
    expect(displayVnd(25000, hidden: true), kHiddenMoney);
    expect(displayVnd(25000, hidden: true, short: true), kHiddenMoneyShort);
  });

  test('greeting follows time of day', () {
    expect(greetingFor(DateTime(2026, 8, 18, 8)), 'Chào buổi sáng');
    expect(greetingFor(DateTime(2026, 8, 18, 15)), 'Chào buổi chiều');
    expect(greetingFor(DateTime(2026, 8, 18, 21)), 'Chào buổi tối');
  });

  test('month label matches Demo copy', () {
    expect(monthLabel(DateTime(2026, 8, 1)), 'Tháng 8 · 2026');
  });
}
