import 'package:cw_core/enumerable_item.dart';

class OrderSourceDescription extends EnumerableItem<int> with Serializable<int> {
  const OrderSourceDescription({required String title, required int raw})
      : super(title: title, raw: raw);

  static const buy = OrderSourceDescription(title: 'Buy', raw: 0);
  static const order = OrderSourceDescription(title: 'Order', raw: 1);

  static OrderSourceDescription deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return buy;
      case 1:
        return order;
      default:
        throw Exception('Invalid OrderSourceDescription raw value: $raw');
    }
  }
}