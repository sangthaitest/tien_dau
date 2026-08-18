import 'payment_method_kind.dart';

/// Named origin of funds (e.g. "MoMo", "Vietcombank"). Not a transaction field dump.
class PaymentSource {
  const PaymentSource({
    required this.id,
    required this.name,
    required this.method,
  });

  final String id;
  final String name;
  final PaymentMethodKind method;
}
