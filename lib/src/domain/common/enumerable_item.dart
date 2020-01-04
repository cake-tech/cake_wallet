import 'package:flutter/foundation.dart';

abstract class EnumerableItem<T> {
  final T raw;
  final String title;

  const EnumerableItem({@required this.title, @required this.raw});

  @override
  String toString() => title;
}

mixin Serializable<T> on EnumerableItem<T> {
  static Serializable deserialize<T>({T raw}) => null;
  T serialize() => raw;
}
