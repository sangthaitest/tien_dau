import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/application/detail_suggestions.dart';
import 'package:tien_day/domain/entities/detail_amount_bucket.dart';

DetailAmountBucket _bucket({
  required String detail,
  required int amount,
  int uses = 1,
  String latestKey = '2026-08-01 12:00 2026-08-01T12:00:00.000Z',
}) {
  return DetailAmountBucket(
    detail: detail,
    amount: amount,
    uses: uses,
    latestKey: latestKey,
  );
}

void main() {
  test('empty history suggests nothing', () {
    expect(suggestDetailAmounts(const []), isEmpty);
  });

  test('one saved expense becomes the suggestion', () {
    expect(suggestDetailAmounts([_bucket(detail: 'Cơm', amount: 27000)]), {
      'Cơm': 27000,
    });
  });

  test('the most used amount wins over a newer different amount', () {
    expect(
      suggestDetailAmounts([
        _bucket(detail: 'Cơm', amount: 27000, uses: 3, latestKey: '2026-08-01'),
        _bucket(detail: 'Cơm', amount: 35000, uses: 1, latestKey: '2026-08-20'),
      ]),
      {'Cơm': 27000},
    );
  });

  test('equal frequency keeps the amount used most recently', () {
    expect(
      suggestDetailAmounts([
        _bucket(
          detail: 'Bún',
          amount: 30000,
          uses: 2,
          latestKey: '2026-08-10 08:00 2026-08-10T01:00:00.000Z',
        ),
        _bucket(
          detail: 'Bún',
          amount: 32000,
          uses: 2,
          latestKey: '2026-08-10 12:30 2026-08-10T05:30:00.000Z',
        ),
      ]),
      {'Bún': 32000},
    );
  });

  test('suggestions stay separate per detail and ignore blanks', () {
    final suggestions = suggestDetailAmounts([
      _bucket(detail: 'Highlands', amount: 29000),
      _bucket(detail: 'Ô Bầu', amount: 22000),
      _bucket(detail: '   ', amount: 15000),
      _bucket(detail: 'Cơm', amount: 0),
    ]);
    expect(suggestions, {'Highlands': 29000, 'Ô Bầu': 22000});
  });

  test('lookup matches the stored spelling without changing it', () {
    const suggestions = {'Cơm': 27000};
    expect(lookupDetailSuggestion('Cơm', suggestions), 27000);
    expect(lookupDetailSuggestion('cơm', suggestions), 27000);
    expect(lookupDetailSuggestion('Bún', suggestions), isNull);
  });
}
