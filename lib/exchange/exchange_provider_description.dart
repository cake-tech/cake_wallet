import 'package:cake_wallet/entities/enumerable_item.dart';

class ExchangeProviderDescription extends EnumerableItem<int>
    with Serializable<int> {
  const ExchangeProviderDescription({String title, int raw})
      : super(title: title, raw: raw);

  static const xmrto = ExchangeProviderDescription(title: 'XMR.TO', raw: 0);
  static const changeNow =
      ExchangeProviderDescription(title: 'ChangeNOW', raw: 1);
  static const morphToken =
      ExchangeProviderDescription(title: 'MorphToken', raw: 2);
  static const sideshift =
  ExchangeProviderDescription(title: 'SideShift.ai', raw: 3);

  static ExchangeProviderDescription deserialize({int raw}) {
    switch (raw) {
      case 0:
        return xmrto;
      case 1:
        return changeNow;
      case 2:
        return morphToken;
      case 3:
        return sideshift;
      default:
        return null;
    }
  }
}
