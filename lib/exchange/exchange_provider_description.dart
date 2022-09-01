import 'package:cw_core/enumerable_item.dart';

class ExchangeProviderDescription extends EnumerableItem<int>
    with Serializable<int> {
  const ExchangeProviderDescription({String title, int raw, this.horizontalLogo = false, this.image})
      : super(title: title, raw: raw);

  final bool horizontalLogo;
  final String image;

  static const xmrto = ExchangeProviderDescription(title: 'XMR.TO', raw: 0, image: 'assets/images/xmrto.png');
  static const changeNow =
      ExchangeProviderDescription(title: 'ChangeNOW', raw: 1, image: 'assets/images/changenow.png');
  static const morphToken =
      ExchangeProviderDescription(title: 'MorphToken', raw: 2, image: 'assets/images/morph.png');

   static const sideShift =
      ExchangeProviderDescription(title: 'SideShift', raw: 3, image: 'assets/images/sideshift.png');

  static const simpleSwap =
      ExchangeProviderDescription(title: 'SimpleSwap', raw: 4, image: 'assets/images/simpleSwap.png');

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
