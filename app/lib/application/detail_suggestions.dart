import '../domain/entities/detail_amount_bucket.dart';

/// Most-used amount for each detail. Ties keep the amount used most recently.
///
/// Keys use the spelling of that latest use. Empty details and non-positive
/// amounts are ignored. This does not average amounts.
Map<String, int> suggestDetailAmounts(Iterable<DetailAmountBucket> buckets) {
  final folded = <String, Map<int, _AmountStats>>{};
  for (final bucket in buckets) {
    final detail = bucket.detail.trim();
    if (detail.isEmpty || bucket.amount <= 0 || bucket.uses <= 0) continue;
    final amounts = folded.putIfAbsent(_fold(detail), () => {});
    final current = amounts[bucket.amount];
    if (current == null || bucket.latestKey.compareTo(current.latestKey) > 0) {
      amounts[bucket.amount] = _AmountStats(
        detail: detail,
        uses: (current?.uses ?? 0) + bucket.uses,
        latestKey: bucket.latestKey,
      );
    } else {
      amounts[bucket.amount] = _AmountStats(
        detail: current.detail,
        uses: current.uses + bucket.uses,
        latestKey: current.latestKey,
      );
    }
  }

  final suggestions = <String, int>{};
  for (final amounts in folded.values) {
    int? bestAmount;
    _AmountStats? best;
    for (final entry in amounts.entries) {
      final stats = entry.value;
      final better =
          best == null ||
          stats.uses > best.uses ||
          (stats.uses == best.uses &&
              stats.latestKey.compareTo(best.latestKey) > 0);
      if (better) {
        bestAmount = entry.key;
        best = stats;
      }
    }
    if (bestAmount != null && best != null) {
      suggestions[best.detail] = bestAmount;
    }
  }
  return suggestions;
}

int? lookupDetailSuggestion(String detail, Map<String, int> suggestions) {
  final clean = detail.trim();
  if (clean.isEmpty) return null;
  final direct = suggestions[clean];
  if (direct != null) return direct;
  final folded = _fold(clean);
  for (final entry in suggestions.entries) {
    if (_fold(entry.key) == folded) return entry.value;
  }
  return null;
}

String _fold(String value) => value.trim().toLowerCase();

class _AmountStats {
  const _AmountStats({
    required this.detail,
    required this.uses,
    required this.latestKey,
  });

  final String detail;
  final int uses;
  final String latestKey;
}
