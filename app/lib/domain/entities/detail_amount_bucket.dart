/// How often one stored detail was saved at one amount.
class DetailAmountBucket {
  const DetailAmountBucket({
    required this.detail,
    required this.amount,
    required this.uses,
    required this.latestKey,
  });

  final String detail;
  final int amount;
  final int uses;

  /// Sortable recency of the latest use: date, time, then created time.
  final String latestKey;
}
