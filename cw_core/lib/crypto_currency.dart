import 'package:cw_core/enumerable_item.dart';
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
    CryptoCurrency.trx,
    CryptoCurrency.usdt,
    CryptoCurrency.usdterc20,
    CryptoCurrency.xlm,
    CryptoCurrency.xrp,
    CryptoCurrency.xhv
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
  static const xhv = CryptoCurrency(title: 'XHV', raw: 16);
  
  static const xag = CryptoCurrency(title: 'XAG', raw: 17);
  static const xau = CryptoCurrency(title: 'XAU', raw: 18);
  static const xaud = CryptoCurrency(title: 'XAUD', raw: 19);
  static const xbtc = CryptoCurrency(title: 'XBTC', raw: 20);
  static const xcad = CryptoCurrency(title: 'XCAD', raw: 21);
  static const xchf = CryptoCurrency(title: 'XCHF', raw: 22);
  static const xcny = CryptoCurrency(title: 'XCNY', raw: 23);
  static const xeur = CryptoCurrency(title: 'XEUR', raw: 24);
  static const xgbp = CryptoCurrency(title: 'XGBP', raw: 25);
  static const xjpy = CryptoCurrency(title: 'XJPY', raw: 26);
  static const xnok = CryptoCurrency(title: 'XNOK', raw: 27);
  static const xnzd = CryptoCurrency(title: 'XNZD', raw: 28);
  static const xusd = CryptoCurrency(title: 'XUSD', raw: 29);

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
      case 16:
        return CryptoCurrency.xhv;
      case 17:
        return CryptoCurrency.xag;
      case 18:
        return CryptoCurrency.xau;
      case 19:
        return CryptoCurrency.xaud;
      case 20:
        return CryptoCurrency.xbtc;
      case 21:
        return CryptoCurrency.xcad;
      case 22:
        return CryptoCurrency.xchf;
      case 23:
        return CryptoCurrency.xcny;
      case 24:
        return CryptoCurrency.xeur;
      case 25:
        return CryptoCurrency.xgbp;
      case 26:
        return CryptoCurrency.xjpy;
      case 27:
        return CryptoCurrency.xnok;
      case 28:
        return CryptoCurrency.xnzd;
      case 29:
        return CryptoCurrency.xusd;
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
      case 'xhv':
        return CryptoCurrency.xhv;
      case 'xag':
        return CryptoCurrency.xag;
      case 'xau':
        return CryptoCurrency.xau;
      case 'xaud':
        return CryptoCurrency.xaud;
      case 'xbtc':
        return CryptoCurrency.xbtc;
      case 'xcad':
        return CryptoCurrency.xcad;
      case 'xchf':
        return CryptoCurrency.xchf;
      case 'xcny':
        return CryptoCurrency.xcny;
      case 'xeur':
        return CryptoCurrency.xeur;
      case 'xgbp':
        return CryptoCurrency.xgbp;
      case 'xjpy':
        return CryptoCurrency.xjpy;
      case 'xnok':
        return CryptoCurrency.xnok;
      case 'xnzd':
        return CryptoCurrency.xnzd;
      case 'xusd':
        return CryptoCurrency.xusd;
      default:
        return null;
    }
  }

  @override
  String toString() => title;
}
