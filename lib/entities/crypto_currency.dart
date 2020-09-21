import 'package:cake_wallet/entities/enumerable_item.dart';
import 'package:hive/hive.dart';

part 'crypto_currency.g.dart';

@HiveType(typeId: 0)
class CryptoCurrency extends EnumerableItem<int> with Serializable<int> {
  const CryptoCurrency({final String title, final int raw})
      : super(title: title, raw: raw);

  static const all = [
    CryptoCurrency.xmr,
    CryptoCurrency.ada,
    CryptoCurrency.bch,
    CryptoCurrency.bnb,
    CryptoCurrency.btc,
    CryptoCurrency.dash,
    CryptoCurrency.eos,
    CryptoCurrency.eth,
    CryptoCurrency.ltc,
    CryptoCurrency.nano,
    CryptoCurrency.trx,
    CryptoCurrency.usdt,
    CryptoCurrency.xlm,
    CryptoCurrency.xrp
  ];
  static const xmr = CryptoCurrency(title: 'XMR', raw: 0);
  static const ada = CryptoCurrency(title: 'ADA', raw: 1);
  static const bch = CryptoCurrency(title: 'BCH', raw: 2);
  static const bnb = CryptoCurrency(title: 'BNB', raw: 3);
  static const btc = CryptoCurrency(title: 'BTC', raw: 4);
  static const dash = CryptoCurrency(title: 'DASH', raw: 5);
  static const eos = CryptoCurrency(title: 'EOS', raw: 6);
  static const eth = CryptoCurrency(title: 'ETH', raw: 7);
  static const ltc = CryptoCurrency(title: 'LTC', raw: 8);
  static const nano = CryptoCurrency(title: 'NANO', raw: 9);
  static const trx = CryptoCurrency(title: 'TRX', raw: 10);
  static const usdt = CryptoCurrency(title: 'USDT', raw: 11);
  static const xlm = CryptoCurrency(title: 'XLM', raw: 12);
  static const xrp = CryptoCurrency(title: 'XRP', raw: 13);

  static CryptoCurrency deserialize({int raw}) {
    switch (raw) {
      case 0:
        return CryptoCurrency.xmr;
      case 1:
        return CryptoCurrency.ada;
      case 2:
        return CryptoCurrency.bch;
      case 3:
        return CryptoCurrency.bnb;
      case 4:
        return CryptoCurrency.btc;
      case 5:
        return CryptoCurrency.dash;
      case 6:
        return CryptoCurrency.eos;
      case 7:
        return CryptoCurrency.eth;
      case 8:
        return CryptoCurrency.ltc;
      case 9:
        return CryptoCurrency.nano;
      case 10:
        return CryptoCurrency.trx;
      case 11:
        return CryptoCurrency.usdt;
      case 12:
        return CryptoCurrency.xlm;
      case 13:
        return CryptoCurrency.xrp;
      default:
        return null;
    }
  }

  static CryptoCurrency fromString(String raw) {
    switch (raw.toLowerCase()) {
      case 'xmr':
        return CryptoCurrency.xmr;
      case 'ada':
        return CryptoCurrency.ada;
      case 'bch':
        return CryptoCurrency.bch;
      case 'bnb':
        return CryptoCurrency.bnb;
      case 'btc':
        return CryptoCurrency.btc;
      case 'dash':
        return CryptoCurrency.dash;
      case 'eos':
        return CryptoCurrency.eos;
      case 'eth':
        return CryptoCurrency.eth;
      case 'ltc':
        return CryptoCurrency.ltc;
      case 'nano':
        return CryptoCurrency.nano;
      case 'trx':
        return CryptoCurrency.trx;
      case 'usdt':
        return CryptoCurrency.usdt;
      case 'xlm':
        return CryptoCurrency.xlm;
      case 'xrp':
        return CryptoCurrency.xrp;
      default:
        return null;
    }
  }

  @override
  String toString() => title;
}
