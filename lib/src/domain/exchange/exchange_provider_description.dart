import 'package:cake_wallet/src/domain/common/enumerable_item.dart';

class ExchangeProviderDescription extends EnumerableItem<int>
    with Serializable<int> {
  static const xmrto = ExchangeProviderDescription(title: 'XMR.TO', raw: 0);
  static const changeNow =
      ExchangeProviderDescription(title: 'ChangeNOW', raw: 1);

  static ExchangeProviderDescription deserialize({int raw}) {
    switch (raw) {
      case 0:
        return xmrto;
      case 1:
        return changeNow;
      default:
        return null;
    }
  }

  final String title;

  const ExchangeProviderDescription({this.title, int raw})
      : super(title: title, raw: raw);
}
