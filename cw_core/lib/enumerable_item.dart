import 'package:flutter/foundation.dart';

abstract class EnumerableItem<T> {
  const EnumerableItem({required this.title, required this.raw});

  final T raw;
  final String title;

  @override
  String toString() => title;
}

mixin Serializable<T> on EnumerableItem<T> {
  static Serializable deserialize<T>({required T raw}) => throw Exception('Unimplemented');
  T serialize() => raw;
}
