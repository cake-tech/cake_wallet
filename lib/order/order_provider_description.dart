import 'package:cw_core/enumerable_item.dart';

class OrderProviderDescription extends EnumerableItem<int> with Serializable<int> {
  const OrderProviderDescription({
    required String title,
    required int raw,
    required this.image,
  }) : super(title: title, raw: raw);

  final String image;

  static const cakePay = OrderProviderDescription(
      title: 'Cake Pay', raw: 0, image: 'assets/images/cake_pay_icon.png');

  static OrderProviderDescription deserialize({required int raw}) {
    switch (raw) {
      case 0:
        return cakePay;
      default:
        throw Exception('Invalid OrderProviderDescription $raw');
    }
  }
}
