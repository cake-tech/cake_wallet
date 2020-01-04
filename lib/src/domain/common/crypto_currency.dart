import 'package:cake_wallet/src/domain/common/enumerable_item.dart';
import 'package:hive/hive.dart';

part 'crypto_currency.g.dart';

@HiveType()
class CryptoCurrency extends EnumerableItem<int> with Serializable<int> {
  static const all = [
    CryptoCurrency.xmr,
    CryptoCurrency.btc,
    CryptoCurrency.eth,
    CryptoCurrency.ltc,
    CryptoCurrency.bch,
    CryptoCurrency.dash
  ];
  static const xmr = CryptoCurrency(title: 'XMR', raw: 0);
  static const btc = CryptoCurrency(title: 'BTC', raw: 1);
  static const eth = CryptoCurrency(title: 'ETH', raw: 2);
  static const ltc = CryptoCurrency(title: 'LTC', raw: 3);
  static const bch = CryptoCurrency(title: 'BCH', raw: 4);
  static const dash = CryptoCurrency(title: 'DASH', raw: 5);

  static CryptoCurrency deserialize({int raw}) {
    switch (raw) {
      case 0:
        return xmr;
      case 1:
        return btc;
      case 2:
        return eth;
      case 3:
        return ltc;
      case 4:
        return bch;
      case 5:
        return dash;
      default:
        return null;
    }
  }

  static CryptoCurrency fromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'xmr':
        return xmr;
      case 'btc':
        return btc;
      case 'eth':
        return eth;
      case 'ltc':
        return ltc;
      case 'bch':
        return bch;
      case 'dash':
        return dash;
      default:
        return null;
    }
  }

  const CryptoCurrency({final String title, final int raw})
      : super(title: title, raw: raw);

  @override
  String toString() => title;
}
