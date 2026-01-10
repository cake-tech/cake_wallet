import 'package:cw_core/enumerable_item.dart';

abstract class TransactionPriority extends EnumerableItem<int>
    with Serializable<int> {
  final String? description;
  final String? hint;

  const TransactionPriority({required String title, required int raw, this.description, this.hint}) : super(title: title, raw: raw);
}
