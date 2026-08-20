/// Reorder helpers for catalog and prototype manage lists.
int adjustedReorderIndex(int oldIndex, int newIndex) {
  return oldIndex < newIndex ? newIndex - 1 : newIndex;
}

List<T> moveAt<T>(List<T> items, int from, int to) {
  if (from == to ||
      from < 0 ||
      to < 0 ||
      from >= items.length ||
      to >= items.length) {
    return List<T>.from(items);
  }
  final next = [...items];
  final item = next.removeAt(from);
  next.insert(to, item);
  return next;
}

List<T> moveVisible<T>(
  List<T> items,
  bool Function(T item) isVisible,
  int fromVisible,
  int toVisible,
) {
  final visible = [for (final item in items) if (isVisible(item)) item];
  final moved = moveAt(visible, fromVisible, toVisible);
  var index = 0;
  return [
    for (final item in items)
      if (isVisible(item)) moved[index++] else item,
  ];
}
