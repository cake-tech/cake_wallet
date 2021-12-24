import 'package:cw_core/enumerable_item.dart';

abstract class TransactionPriority extends EnumerableItem<int>
    with Serializable<int> {
  const TransactionPriority({String title, int raw}) : super(title: title, raw: raw);
}
