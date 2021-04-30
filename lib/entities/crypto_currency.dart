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
    CryptoCurrency.dai,
    CryptoCurrency.dash,
    CryptoCurrency.eos,
    CryptoCurrency.eth,
    CryptoCurrency.ltc,
    CryptoCurrency.nano,
    CryptoCurrency.trx,
    CryptoCurrency.usdt,
    CryptoCurrency.usdterc20,
    CryptoCurrency.xlm,
    CryptoCurrency.xrp
  ];
  static const xmr = CryptoCurrency(title: 'XMR', raw: 0);
  static const ada = CryptoCurrency(title: 'ADA', raw: 1);
  static const bch = CryptoCurrency(title: 'BCH', raw: 2);
  static const bnb = CryptoCurrency(title: 'BNB BEP2', raw: 3);
  static const btc = CryptoCurrency(title: 'BTC', raw: 4);
  static const dai = CryptoCurrency(title: 'DAI', raw: 5);
  static const dash = CryptoCurrency(title: 'DASH', raw: 6);
  static const eos = CryptoCurrency(title: 'EOS', raw: 7);
  static const eth = CryptoCurrency(title: 'ETH', raw: 8);
  static const ltc = CryptoCurrency(title: 'LTC', raw: 9);
  static const nano = CryptoCurrency(title: 'NANO', raw: 10);
  static const trx = CryptoCurrency(title: 'TRX', raw: 11);
  static const usdt = CryptoCurrency(title: 'USDT', raw: 12);
  static const usdterc20 = CryptoCurrency(title: 'USDTERC20', raw: 13);
  static const xlm = CryptoCurrency(title: 'XLM', raw: 14);
  static const xrp = CryptoCurrency(title: 'XRP', raw: 15);

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
        return CryptoCurrency.dai;
      case 6:
        return CryptoCurrency.dash;
      case 7:
        return CryptoCurrency.eos;
      case 8:
        return CryptoCurrency.eth;
      case 9:
        return CryptoCurrency.ltc;
      case 10:
        return CryptoCurrency.nano;
      case 11:
        return CryptoCurrency.trx;
      case 12:
        return CryptoCurrency.usdt;
      case 13:
        return CryptoCurrency.usdterc20;
      case 14:
        return CryptoCurrency.xlm;
      case 15:
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
      case 'bnbmainnet':
        return CryptoCurrency.bnb;
      case 'btc':
        return CryptoCurrency.btc;
      case 'dai':
        return CryptoCurrency.dai;
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
      case 'usdterc20':
        return CryptoCurrency.usdterc20;
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
