extension ComparableList<T extends Comparable<T>> on Iterable<T> {
  T get max => reduce((curr, next) => curr.compareTo(next) > 0 ? curr : next);
  T get min => reduce((curr, next) => curr.compareTo(next) < 0 ? curr : next);
}
