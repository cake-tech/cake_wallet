import 'package:cw_core/enumerable_item.dart';

class ExchangeProviderDescription extends EnumerableItem<int>
    with Serializable<int> {
  const ExchangeProviderDescription({String title, int raw})
      : super(title: title, raw: raw);

  static const xmrto = ExchangeProviderDescription(title: 'XMR.TO', raw: 0);
  static const changeNow =
      ExchangeProviderDescription(title: 'ChangeNOW', raw: 1);
  static const morphToken =
      ExchangeProviderDescription(title: 'MorphToken', raw: 2);

   static const sideShift =
      ExchangeProviderDescription(title: 'SideShift', raw: 3);
  
   static const simpleSwap =
      ExchangeProviderDescription(title: 'SimpleSwap', raw: 4);

  static ExchangeProviderDescription deserialize({int raw}) {
    switch (raw) {
      case 0:
        return xmrto;
      case 1:
        return changeNow;
      case 2:
        return morphToken;
      case 3:
        return sideShift;
      case 4:
        return simpleSwap;
      default:
        return null;
    }
  }
}
