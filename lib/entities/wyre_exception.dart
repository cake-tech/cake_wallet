class WyreException implements Exception {
  WyreException(this.description);

  String description;

  @override
  String toString() => description;
}