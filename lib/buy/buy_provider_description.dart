import 'package:cw_core/enumerable_item.dart';

class BuyProviderDescription extends EnumerableItem<int>
    with Serializable<int> {
    const BuyProviderDescription({required String title, required int raw})
      : super(title: title, raw: raw);

    static const wyre = BuyProviderDescription(title: 'Wyre', raw: 0);
    static const moonPay = BuyProviderDescription(title: 'MoonPay', raw: 1);

    static BuyProviderDescription deserialize({required int raw}) {
      switch (raw) {
        case 0:
          return wyre;
        case 1:
          return moonPay;
        default:
          throw Exception('Incorrect token $raw  for BuyProviderDescription deserialize');
      }
    }
}