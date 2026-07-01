extension EnhancedList<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}


String middleTruncate(String s, int head, int tail) {
  if (s.length <= head + tail + 3) return s;
  return s.substring(0, head) + '...' + s.substring(s.length - tail);
}