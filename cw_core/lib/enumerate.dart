abstract class Enumerate {
  String get value;

  @override
  bool operator ==(other) {
    if (identical(other, this)) return true;
    if (other is! Enumerate) return false;
    return other.runtimeType == runtimeType && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;
}
