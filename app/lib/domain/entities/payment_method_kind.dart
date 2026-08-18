/// How money moved (cash, wallet, card, bank). Distinct from the named source.
enum PaymentMethodKind {
  cash,
  bankAccount,
  eWallet,
  creditCard,
  debitCard,
  other;

  String get storageValue => name;

  static PaymentMethodKind fromStorage(String raw) {
    return PaymentMethodKind.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException('Unknown payment method: $raw'),
    );
  }
}
