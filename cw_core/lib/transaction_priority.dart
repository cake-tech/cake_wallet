import 'package:cw_core/enumerable_item.dart';

abstract class TransactionPriority extends EnumerableItem<int> with Serializable<int> {
  const TransactionPriority({required super.title, required super.raw});

  String get units => '';
  String getUnits(int rate) {
    return rate == 1 ? units : '${units}s';
  }

  String toString() {
    return title;
  }
}

abstract class TransactionPriorities {
  const TransactionPriorities();
  int operator [](TransactionPriority type);
  String labelWithRate(TransactionPriority type);
  Map<String, int> toJson();
  factory TransactionPriorities.fromJson(Map<String, int> json) {
    throw UnimplementedError();
  }
}
