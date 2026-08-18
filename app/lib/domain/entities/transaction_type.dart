enum TransactionType {
  expense,
  income;

  String get storageValue => name;

  static TransactionType fromStorage(String raw) {
    return TransactionType.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => throw FormatException('Unknown transaction type: $raw'),
    );
  }
}
