import 'package:cw_core/enumerable_item.dart';
import 'package:hive/hive.dart';

part 'crypto_currency.g.dart';

@HiveType(typeId: 0)
class CryptoCurrency extends EnumerableItem<int> with Serializable<int> {
  const CryptoCurrency({
    String title = '',
    int raw = -1,
    this.name,
    this.iconPath,
    this.tag,})
      : super(title: title, raw: raw);

  final String? tag;
  final String? name;
  final String? iconPath;

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
    CryptoCurrency.xrp,
    CryptoCurrency.xhv,
    CryptoCurrency.ape,
    CryptoCurrency.avaxc,
    CryptoCurrency.btt,
    CryptoCurrency.bttbsc,
    CryptoCurrency.doge,
    CryptoCurrency.firo,
    CryptoCurrency.usdttrc20,
    CryptoCurrency.hbar,
    CryptoCurrency.sc,
    CryptoCurrency.sol,
    CryptoCurrency.usdc,
    CryptoCurrency.usdcsol,
    CryptoCurrency.zaddr,
    CryptoCurrency.zec,
    CryptoCurrency.zen,
    CryptoCurrency.xvg,
  ];

  static const xmr = CryptoCurrency(title: 'XMR', iconPath: 'assets/images/monero_icon.png', name: 'Monero', raw: 0);
  static const ada = CryptoCurrency(title: 'ADA', iconPath: 'assets/images/ada_icon.png', name: 'Cardano', raw: 1);
  static const bch = CryptoCurrency(title: 'BCH', iconPath: 'assets/images/bch_icon.png',name: 'Bitcoin Cash', raw: 2);
  static const bnb = CryptoCurrency(title: 'BNB', iconPath: 'assets/images/bnb_icon.png', tag: 'BSC', name: 'Binance Coin', raw: 3);
  static const btc = CryptoCurrency(title: 'BTC', iconPath: 'assets/images/btc.png', name: 'Bitcoin', raw: 4);
  static const dai = CryptoCurrency(title: 'DAI', iconPath: 'assets/images/dai_icon.png', tag: 'ETH', name: 'Dai', raw: 5);
  static const dash = CryptoCurrency(title: 'DASH', iconPath: 'assets/images/dash_icon.png', name: 'Dash', raw: 6);
  static const eos = CryptoCurrency(title: 'EOS', iconPath: 'assets/images/eos_icon.png', name: 'EOS', raw: 7);
  static const eth = CryptoCurrency(title: 'ETH', iconPath: 'assets/images/eth_icon.png', name: 'Ethereum', raw: 8);
  static const ltc = CryptoCurrency(title: 'LTC', iconPath: 'assets/images/litecoin-ltc_icon.png', name: 'Litecoin', raw: 9);
  static const nano = CryptoCurrency(title: 'NANO', raw: 10);
  static const trx = CryptoCurrency(title: 'TRX', iconPath: 'assets/images/trx_icon.png', name: 'TRON', raw: 11);
  static const usdt = CryptoCurrency(title: 'USDT', iconPath: 'assets/images/usdt_icon.png', tag: 'OMNI', name: 'USDT', raw: 12);
  static const usdterc20 = CryptoCurrency(title: 'USDT', iconPath: 'assets/images/usdterc20_icon.png', tag: 'ETH', name: 'USDT', raw: 13);
  static const xlm = CryptoCurrency(title: 'XLM', iconPath: 'assets/images/xlm_icon.png', name: 'Stellar', raw: 14);
  static const xrp = CryptoCurrency(title: 'XRP', iconPath: 'assets/images/xrp_icon.png', name: 'Ripple', raw: 15);
  static const xhv = CryptoCurrency(title: 'XHV', iconPath: 'assets/images/xhv_logo.png', name: 'Haven Protocol', raw: 16);

  static const xag = CryptoCurrency(title: 'XAG', tag: 'XHV',  raw: 17);
  static const xau = CryptoCurrency(title: 'XAU', tag: 'XHV', raw: 18);
  static const xaud = CryptoCurrency(title: 'XAUD', tag: 'XHV', raw: 19);
  static const xbtc = CryptoCurrency(title: 'XBTC', tag: 'XHV', raw: 20);
  static const xcad = CryptoCurrency(title: 'XCAD', tag: 'XHV', raw: 21);
  static const xchf = CryptoCurrency(title: 'XCHF', tag: 'XHV', raw: 22);
  static const xcny = CryptoCurrency(title: 'XCNY', tag: 'XHV', raw: 23);
  static const xeur = CryptoCurrency(title: 'XEUR', tag: 'XHV', raw: 24);
  static const xgbp = CryptoCurrency(title: 'XGBP', tag: 'XHV', raw: 25);
  static const xjpy = CryptoCurrency(title: 'XJPY', tag: 'XHV', raw: 26);
  static const xnok = CryptoCurrency(title: 'XNOK', tag: 'XHV', raw: 27);
  static const xnzd = CryptoCurrency(title: 'XNZD', tag: 'XHV', raw: 28);
  static const xusd = CryptoCurrency(title: 'XUSD', tag: 'XHV', raw: 29);

  static const ape = CryptoCurrency(title: 'APE', iconPath: 'assets/images/ape_icon.png', tag: 'ETH', raw: 30);
  static const avaxc = CryptoCurrency(title: 'AVAX', iconPath: 'assets/images/avaxc_icon.png', tag: 'C-CHAIN', raw: 31);
  static const btt = CryptoCurrency(title: 'BTT', iconPath: 'assets/images/btt_icon.png', raw: 32);
  static const bttbsc = CryptoCurrency(title: 'BTT', iconPath: 'assets/images/bttbsc_icon.png', tag: 'BSC', raw: 33);
  static const doge = CryptoCurrency(title: 'DOGE', iconPath: 'assets/images/doge_icon.png', raw: 34);
  static const firo = CryptoCurrency(title: 'FIRO', iconPath: 'assets/images/firo_icon.png', raw: 35);
  static const usdttrc20 = CryptoCurrency(title: 'USDT', iconPath: 'assets/images/usdttrc20_icon.png', tag: 'TRX', raw: 36);
  static const hbar = CryptoCurrency(title: 'HBAR', iconPath: 'assets/images/hbar_icon.png', raw: 37);
  static const sc = CryptoCurrency(title: 'SC', iconPath: 'assets/images/sc_icon.png', raw: 38);
  static const sol = CryptoCurrency(title: 'SOL', iconPath: 'assets/images/sol_icon.png', raw: 39);
  static const usdc = CryptoCurrency(title: 'USDC', iconPath: 'assets/images/usdc_icon.png', tag: 'ETH', raw: 40);
  static const usdcsol = CryptoCurrency(title: 'USDC', iconPath: 'assets/images/usdcsol_icon.png', tag: 'SOL', raw: 41);
  static const zaddr = CryptoCurrency(title: 'ZZEC', tag: 'ZEC', name: 'Shielded Zcash', iconPath: 'assets/images/zaddr_icon.png', raw: 42);
  static const zec = CryptoCurrency(title: 'TZEC', tag: 'ZEC', name: 'Transparent Zcash', iconPath: 'assets/images/zec_icon.png', raw: 43);
  static const zen = CryptoCurrency(title: 'ZEN', iconPath: 'assets/images/zen_icon.png', raw: 44);
  static const xvg = CryptoCurrency(title: 'XVG', name: 'Verge', iconPath: 'assets/images/xvg_icon.png', raw: 45);

  static CryptoCurrency deserialize({required int raw}) {
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
        return CryptoCurrency.zaddr;
      case 43:
        return CryptoCurrency.zec;
      case 44:
        return CryptoCurrency.zen;
      case 45:
        return CryptoCurrency.xvg;
      default:
        throw Exception('Unexpected token: $raw for CryptoCurrency deserialize');
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
      case 'usdc':
        return CryptoCurrency.usdc;
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
      case 'ape':
        return CryptoCurrency.ape;
      case 'avax':
        return CryptoCurrency.avaxc;
      case 'btt':
        return CryptoCurrency.btt;
      case 'bttbsc':
        return CryptoCurrency.bttbsc;
      case 'doge':
        return CryptoCurrency.doge;
      case 'firo':
        return CryptoCurrency.firo;
      case 'usdttrc20':
        return CryptoCurrency.usdttrc20;
      case 'hbar':
        return CryptoCurrency.hbar;
      case 'sc':
        return CryptoCurrency.sc;
      case 'sol':
        return CryptoCurrency.sol;
      case 'usdt':
        return CryptoCurrency.usdt;
      case 'usdcsol':
        return CryptoCurrency.usdcsol;
      case 'zaddr':
        return CryptoCurrency.zaddr;
      case 'zec':
        return CryptoCurrency.zec;
      case 'zen':
        return CryptoCurrency.zen;
      case 'xvg':
        return CryptoCurrency.xvg;
      default:
        throw Exception('Unexpected token: $raw for CryptoCurrency fromString');
    }
  }

  @override
  String toString() => title;
}
