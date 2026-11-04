import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tien_day/domain/entities/payment_method_kind.dart';
import 'package:tien_day/presentation/theme/payment_look.dart';

void main() {
  test('named methods keep their own colors', () {
    final cash = paymentLook(
      sourceId: 'cash',
      name: 'Tiền mặt',
      method: PaymentMethodKind.cash,
    );
    final card = paymentLook(
      sourceId: 'card',
      name: 'Thẻ ngân hàng',
      method: PaymentMethodKind.creditCard,
    );
    final momo = paymentLook(
      sourceId: 'momo',
      name: 'MoMo',
      method: PaymentMethodKind.eWallet,
    );
    final missing = paymentLook(
      sourceId: '',
      name: 'Chưa có phương thức',
      method: PaymentMethodKind.cash,
    );
    final vcb = paymentLook(
      sourceId: 'vcb',
      name: 'Vietcombank',
      method: PaymentMethodKind.bankAccount,
    );
    final tcb = paymentLook(
      sourceId: 'tcb',
      name: 'Techcombank',
      method: PaymentMethodKind.bankAccount,
    );

    expect(cash.color, const Color(0xFF00B67A));
    expect(card.color, const Color(0xFF2F80ED));
    expect(momo.color, const Color(0xFF7B4DFF));
    expect(missing.color, isNot(cash.color));
    expect(vcb.color, isNot(tcb.color));
    expect(vcb.color, isNot(cash.color));
    expect(vcb.color, isNot(card.color));
    expect(vcb.color, isNot(momo.color));
  });
}
