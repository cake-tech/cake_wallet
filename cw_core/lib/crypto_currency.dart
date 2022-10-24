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
    CryptoCurrency.usdcpoly,
    CryptoCurrency.dcr,
    CryptoCurrency.husd,
    CryptoCurrency.kmd,
    CryptoCurrency.mana,
    CryptoCurrency.maticpoly,
    CryptoCurrency.matic,
    CryptoCurrency.mkr,
    CryptoCurrency.near,
    CryptoCurrency.oxt,
    CryptoCurrency.paxg,
    CryptoCurrency.pivx,
    CryptoCurrency.rune,
    CryptoCurrency.rvn,
    CryptoCurrency.scrt,
    CryptoCurrency.uni,
    CryptoCurrency.stx,
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

  static const usdcpoly = CryptoCurrency(title: 'USDC', iconPath: 'assets/images/usdc_icon.png', tag: 'POLY', raw: 46);
  static const dcr = CryptoCurrency(title: 'DCR', iconPath: 'assets/images/dcr_icon.png', raw: 47);
  static const husd = CryptoCurrency(title: 'HUSD', iconPath: 'assets/images/husd_icon.png', tag: 'ETH', raw: 48);
  static const kmd = CryptoCurrency(title: 'KMD', iconPath: 'assets/images/kmd_icon.png', raw: 49);
  static const mana = CryptoCurrency(title: 'MANA', iconPath: 'assets/images/mana_icon.png', tag: 'ETH', raw: 50);
  static const maticpoly = CryptoCurrency(title: 'MATIC', iconPath: 'assets/images/matic_icon.png', tag: 'POLY', raw: 51);
  static const matic = CryptoCurrency(title: 'MATIC', iconPath: 'assets/images/matic_icon.png', tag: 'ETH', raw: 52);
  static const mkr = CryptoCurrency(title: 'MKR', iconPath: 'assets/images/mkr_icon.png', tag: 'ETH', raw: 53);
  static const near = CryptoCurrency(title: 'NEAR', iconPath: 'assets/images/near_icon.png', raw: 54);
  static const oxt = CryptoCurrency(title: 'OXT', iconPath: 'assets/images/oxt_icon.png', tag: 'ETH', raw: 55);
  static const paxg = CryptoCurrency(title: 'PAXG', iconPath: 'assets/images/paxg_icon.png', tag: 'ETH', raw: 56);
  static const pivx = CryptoCurrency(title: 'PIVX', iconPath: 'assets/images/pivx_icon.png', raw: 57);
  static const rune = CryptoCurrency(title: 'RUNE', iconPath: 'assets/images/rune_icon.png', raw: 58);
  static const rvn = CryptoCurrency(title: 'RVN', iconPath: 'assets/images/rvn_icon.png', raw: 59);
  static const scrt = CryptoCurrency(title: 'SCRT', iconPath: 'assets/images/scrt_icon.png', raw: 60);
  static const uni = CryptoCurrency(title: 'UNI', iconPath: 'assets/images/uni_icon.png', tag: 'ETH', raw: 61);
  static const stx = CryptoCurrency(title: 'STX', iconPath: 'assets/images/stx_icon.png', raw: 62);

  static const mapFromInt = {
    0: CryptoCurrency.xmr,
    1: CryptoCurrency.ada,
    2: CryptoCurrency.bch,
    3: CryptoCurrency.bnb,
    4: CryptoCurrency.btc,
    5: CryptoCurrency.dai,
    6: CryptoCurrency.dash,
    7: CryptoCurrency.eos,
    8: CryptoCurrency.eth,
    9: CryptoCurrency.ltc,
    10: CryptoCurrency.nano,
    11: CryptoCurrency.trx,
    12: CryptoCurrency.usdt,
    13: CryptoCurrency.usdterc20,
    14: CryptoCurrency.xlm,
    15: CryptoCurrency.xrp,
    16: CryptoCurrency.xhv,
    17: CryptoCurrency.xag,
    18: CryptoCurrency.xau,
    19: CryptoCurrency.xaud,
    20: CryptoCurrency.xbtc,
    21: CryptoCurrency.xcad,
    22: CryptoCurrency.xchf,
    23: CryptoCurrency.xcny,
    24: CryptoCurrency.xeur,
    25: CryptoCurrency.xgbp,
    26: CryptoCurrency.xjpy,
    27: CryptoCurrency.xnok,
    28: CryptoCurrency.xnzd,
    29: CryptoCurrency.xusd,
    30: CryptoCurrency.ape,
    31: CryptoCurrency.avaxc,
    32: CryptoCurrency.btt,
    33: CryptoCurrency.bttbsc,
    34: CryptoCurrency.doge,
    35: CryptoCurrency.firo,
    36: CryptoCurrency.usdttrc20,
    37: CryptoCurrency.hbar,
    38: CryptoCurrency.sc,
    39: CryptoCurrency.sol,
    40: CryptoCurrency.usdc,
    41: CryptoCurrency.usdcsol,
    42: CryptoCurrency.zaddr,
    43: CryptoCurrency.zec,
    44: CryptoCurrency.zen,
    45: CryptoCurrency.xvg,
    46: CryptoCurrency.usdcpoly,
    47: CryptoCurrency.dcr,
    48: CryptoCurrency.husd,
    49: CryptoCurrency.kmd,
    50: CryptoCurrency.mana,
    51: CryptoCurrency.maticpoly,
    52: CryptoCurrency.matic,
    53: CryptoCurrency.mkr,
    54: CryptoCurrency.near,
    55: CryptoCurrency.oxt,
    56: CryptoCurrency.paxg,
    57: CryptoCurrency.pivx,
    58: CryptoCurrency.rune,
    59: CryptoCurrency.rvn,
    60: CryptoCurrency.scrt,
    61: CryptoCurrency.uni,
    62: CryptoCurrency.stx
  };

  static const mapFromString = {
    'xmr': CryptoCurrency.xmr,
    'ada': CryptoCurrency.ada,
    'bch': CryptoCurrency.bch,
    'bnb': CryptoCurrency.bnb,
    'btc': CryptoCurrency.btc,
    'dai': CryptoCurrency.dai,
    'dash': CryptoCurrency.dash,
    'eos': CryptoCurrency.eos,
    'eth': CryptoCurrency.eth,
    'ltc': CryptoCurrency.ltc,
    'nano': CryptoCurrency.nano,
    'trx': CryptoCurrency.trx,
    'usdt': CryptoCurrency.usdt,
    'usdterc20': CryptoCurrency.usdterc20,
    'xlm': CryptoCurrency.xlm,
    'xrp': CryptoCurrency.xrp,
    'xhv': CryptoCurrency.xhv,
    'xag': CryptoCurrency.xag,
    'xau': CryptoCurrency.xau,
    'xaud': CryptoCurrency.xaud,
    'xbtc': CryptoCurrency.xbtc,
    'xcad': CryptoCurrency.xcad,
    'xchf': CryptoCurrency.xchf,
    'xcny': CryptoCurrency.xcny,
    'xeur': CryptoCurrency.xeur,
    'xgbp': CryptoCurrency.xgbp,
    'xjpy': CryptoCurrency.xjpy,
    'xnok': CryptoCurrency.xnok,
    'xnzd': CryptoCurrency.xnzd,
    'xusd': CryptoCurrency.xusd,
    'ape': CryptoCurrency.ape,
    'avaxc': CryptoCurrency.avaxc,
    'btt': CryptoCurrency.btt,
    'bttbsc': CryptoCurrency.bttbsc,
    'doge': CryptoCurrency.doge,
    'firo': CryptoCurrency.firo,
    'usdttrc20': CryptoCurrency.usdttrc20,
    'hbar': CryptoCurrency.hbar,
    'sc': CryptoCurrency.sc,
    'sol': CryptoCurrency.sol,
    'usdc': CryptoCurrency.usdc,
    'usdcsol': CryptoCurrency.usdcsol,
    'zaddr': CryptoCurrency.zaddr,
    'zec': CryptoCurrency.zec,
    'zen': CryptoCurrency.zen,
    'xvg': CryptoCurrency.xvg,
    'usdcpoly': CryptoCurrency.usdcpoly,
    'dcr': CryptoCurrency.dcr,
    'husd': CryptoCurrency.husd,
    'kmd': CryptoCurrency.kmd,
    'mana': CryptoCurrency.mana,
    'maticpoly': CryptoCurrency.maticpoly,
    'matic': CryptoCurrency.matic,
    'mkr': CryptoCurrency.mkr,
    'near': CryptoCurrency.near,
    'oxt': CryptoCurrency.oxt,
    'paxg': CryptoCurrency.paxg,
    'pivx': CryptoCurrency.pivx,
    'rune': CryptoCurrency.rune,
    'rvn': CryptoCurrency.rvn,
    'scrt': CryptoCurrency.scrt,
    'uni': CryptoCurrency.uni,
    'stx': CryptoCurrency.stx
  };

  static CryptoCurrency deserialize({required int raw}) {

    if (CryptoCurrency.mapFromInt[raw] == null) {
      final s = 'Unexpected token: $raw for CryptoCurrency deserialize';
      throw  ArgumentError.value(raw, 'raw', s);
    }
    return CryptoCurrency.mapFromInt[raw]!;
  }

  static CryptoCurrency fromString(String raw) {

    if (CryptoCurrency.mapFromString[raw.toLowerCase()] == null) {
      final s = 'Unexpected token: $raw for CryptoCurrency fromString';
      throw  ArgumentError.value(raw, 'raw', s);
    }
    return CryptoCurrency.mapFromString[raw.toLowerCase()]!;
  }

  @override
  String toString() => title;
}
