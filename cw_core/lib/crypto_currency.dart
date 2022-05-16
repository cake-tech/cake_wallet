import 'package:cw_core/enumerable_item.dart';
import 'package:hive/hive.dart';

part 'crypto_currency.g.dart';

@HiveType(typeId: 0)
class CryptoCurrency extends EnumerableItem<int> with Serializable<int> {
  const CryptoCurrency({final String title, final int raw})
      : super(title: title, raw: raw);

  static const all = [
    CryptoCurrency.xmr,
    CryptoCurrency.btc,
    CryptoCurrency.ltc,
    CryptoCurrency.usdterc20,
    CryptoCurrency.usdc,
    CryptoCurrency.ada,
    CryptoCurrency.ape,
    CryptoCurrency.avaxc,
    CryptoCurrency.bch,
    CryptoCurrency.bnb,
    CryptoCurrency.btt,
    CryptoCurrency.bttbsc,
    CryptoCurrency.dai,
    CryptoCurrency.dash,
    CryptoCurrency.doge,
    CryptoCurrency.eos,
    CryptoCurrency.eth,
  	CryptoCurrency.firo,
  	CryptoCurrency.hbar,
  	CryptoCurrency.nano,
  	CryptoCurrency.sc,
  	CryptoCurrency.sol,
    CryptoCurrency.trx,
    CryptoCurrency.usdcsol,
    CryptoCurrency.usdt,
  	CryptoCurrency.usdttrc20,
  	CryptoCurrency.ust,
  	CryptoCurrency.xhv,
    CryptoCurrency.xlm,
    CryptoCurrency.xrp,
  	CryptoCurrency.xvg,
  	CryptoCurrency.zaddr,
  	CryptoCurrency.zec,
  	CryptoCurrency.zen,
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
  
  static const ape = CryptoCurrency(title: 'APE', raw: 30);
  static const avaxc = CryptoCurrency(title: 'AVAXC', raw: 31);
  static const btt = CryptoCurrency(title: 'BTT', raw: 32);
  static const bttbsc = CryptoCurrency(title: 'BTTBSC', raw: 33);
  static const doge = CryptoCurrency(title: 'DOGE', raw: 34);
  static const firo = CryptoCurrency(title: 'FIRO', raw: 35);
  static const usdttrc20 = CryptoCurrency(title: 'USDTTRC20', raw: 36);
  static const hbar = CryptoCurrency(title: 'HBAR', raw: 37);
  static const sc = CryptoCurrency(title: 'SC', raw: 38);
  static const sol = CryptoCurrency(title: 'SOL', raw: 39);
  static const usdc = CryptoCurrency(title: 'USDC', raw: 40);
  static const usdcsol = CryptoCurrency(title: 'USDCSOL', raw: 41);
  static const ust = CryptoCurrency(title: 'UST', raw: 42);
  static const zaddr = CryptoCurrency(title: 'ZZEC', raw: 43);
  static const zec = CryptoCurrency(title: 'TZEC', raw: 44);
  static const zen = CryptoCurrency(title: 'ZEN', raw: 45);
  static const xvg = CryptoCurrency(title: 'XVG', raw: 46);

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
  	  case 30:
  	    return CryptoCurrency.ape;
  	  case 31:
  	    return CryptoCurrency.avaxc;
  	  case 32:
  	    return CryptoCurrency.btt;
  	  case 33:
  	    return CryptoCurrency.bttbsc;
  	  case 34:
  	    return CryptoCurrency.doge;
  	  case 35:
  	    return CryptoCurrency.firo;
  	  case 36:
  	    return CryptoCurrency.usdttrc20;
  	  case 37:
  	    return CryptoCurrency.hbar;
  	  case 38:
  	    return CryptoCurrency.sc;
  	  case 39:
  	    return CryptoCurrency.sol;
  	  case 40:
  	    return CryptoCurrency.usdc;
  	  case 41:
  	    return CryptoCurrency.usdcsol;
  	  case 42:
  	    return CryptoCurrency.ust;
  	  case 43:
  	    return CryptoCurrency.zaddr;
  	  case 44:
  	    return CryptoCurrency.zec;
  	  case 45:
  	    return CryptoCurrency.zen;
  	  case 46:
  	    return CryptoCurrency.xvg;
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
  	  case 'ape':
        return CryptoCurrency.ape;
  	  case 'avax':
        return CryptoCurrency.avaxc;
      case 'bch':
        return CryptoCurrency.bch;
      case 'bnbmainnet':
        return CryptoCurrency.bnb;
      case 'btc':
        return CryptoCurrency.btc;
  	  case 'btt':
        return CryptoCurrency.btt;
  	  case 'bttbsc':
        return CryptoCurrency.bttbsc;
      case 'dai':
        return CryptoCurrency.dai;
      case 'dash':
        return CryptoCurrency.dash;
  	  case 'doge':
        return CryptoCurrency.doge;
      case 'eos':
        return CryptoCurrency.eos;
      case 'eth':
        return CryptoCurrency.eth;
  	  case 'firo':
        return CryptoCurrency.firo;
  	  case 'hbar':
        return CryptoCurrency.hbar;
      case 'ltc':
        return CryptoCurrency.ltc;
      case 'nano':
        return CryptoCurrency.nano;
  	  case 'sc':
        return CryptoCurrency.sc;
  	  case 'sol':
        return CryptoCurrency.sol;
      case 'trx':
        return CryptoCurrency.trx;
  	  case 'usdc':
        return CryptoCurrency.usdc;
  	  case 'usdcsol':
        return CryptoCurrency.usdcsol;
      case 'usdt':
        return CryptoCurrency.usdt;
      case 'usdterc20':
        return CryptoCurrency.usdterc20;
      case 'usdttrc20':
        return CryptoCurrency.usdttrc20;
      case 'ust':
        return CryptoCurrency.ust;
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
  	  case 'xvg':
        return CryptoCurrency.xvg;
  	  case 'zaddr':
        return CryptoCurrency.zaddr;
  	  case 'zec':
        return CryptoCurrency.zec;
  	  case 'zen':
        return CryptoCurrency.zen;
      default:
        return null;
    }
  }

  @override
  String toString() => title;
}
