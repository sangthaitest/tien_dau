import '../entities/payment_method_kind.dart';
import '../entities/payment_source.dart';

/// V3 payment picker rows mapped to production source + method.
class PaymentOption {
  const PaymentOption({
    required this.source,
    required this.typeLabel,
  });

  final PaymentSource source;
  final String typeLabel;

  String get pickerLabel => '${source.name} — $typeLabel';
}

class PaymentOptionCatalog {
  PaymentOptionCatalog._();

  static const defaultId = 'momo';

  static const all = [
    PaymentOption(
      source: PaymentSource(
        id: 'momo',
        name: 'MoMo',
        method: PaymentMethodKind.eWallet,
      ),
      typeLabel: 'Ví điện tử',
    ),
    PaymentOption(
      source: PaymentSource(
        id: 'vcb',
        name: 'Vietcombank',
        method: PaymentMethodKind.bankAccount,
      ),
      typeLabel: 'Tài khoản ngân hàng',
    ),
    PaymentOption(
      source: PaymentSource(
        id: 'cash',
        name: 'Tiền mặt',
        method: PaymentMethodKind.cash,
      ),
      typeLabel: 'Tiền mặt',
    ),
    PaymentOption(
      source: PaymentSource(
        id: 'tcb',
        name: 'Techcombank',
        method: PaymentMethodKind.bankAccount,
      ),
      typeLabel: 'Tài khoản ngân hàng',
    ),
  ];

  static PaymentOption byId(String id) {
    for (final option in all) {
      if (option.source.id == id) return option;
    }
    return all.first;
  }
}
