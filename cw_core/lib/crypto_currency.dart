import 'package:cw_core/enumerable_item.dart';

class CryptoCurrency extends EnumerableItem<int> with Serializable<int> {
  const CryptoCurrency({
    String title = '',
    int raw = -1,
    required this.name,
    this.fullName,
    this.iconPath,
    this.tag})
      : super(title: title, raw: raw);

  final String name;
  final String? tag;
  final String? fullName;
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
    CryptoCurrency.bttc,
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

  static const havenCurrencies = [
    xag,
    xau,
    xaud,
    xbtc,
    xcad,
    xchf,
    xcny,
    xeur,
    xgbp,
    xjpy,
    xnok,
    xnzd,
    xusd,
  ];

  static const xmr = CryptoCurrency(title: 'XMR', iconPath: 'assets/images/monero_icon.png', fullName: 'Monero', raw: 0, name: 'xmr');
  static const ada = CryptoCurrency(title: 'ADA', iconPath: 'assets/images/ada_icon.png', fullName: 'Cardano', raw: 1, name: 'ada');
  static const bch = CryptoCurrency(title: 'BCH', iconPath: 'assets/images/bch_icon.png',fullName: 'Bitcoin Cash', raw: 2, name: 'bch');
  static const bnb = CryptoCurrency(title: 'BNB', iconPath: 'assets/images/bnb_icon.png', tag: 'BSC', fullName: 'Binance Coin', raw: 3, name: 'bnb');
  static const btc = CryptoCurrency(title: 'BTC', iconPath: 'assets/images/btc.png', fullName: 'Bitcoin', raw: 4, name: 'btc');
  static const dai = CryptoCurrency(title: 'DAI', iconPath: 'assets/images/dai_icon.png', tag: 'ETH', fullName: 'Dai', raw: 5, name: 'dai');
  static const dash = CryptoCurrency(title: 'DASH', iconPath: 'assets/images/dash_icon.png', fullName: 'Dash', raw: 6, name: 'dash');
  static const eos = CryptoCurrency(title: 'EOS', iconPath: 'assets/images/eos_icon.png', fullName: 'EOS', raw: 7, name: 'eos');
  static const eth = CryptoCurrency(title: 'ETH', iconPath: 'assets/images/eth_icon.png', fullName: 'Ethereum', raw: 8, name: 'eth');
  static const ltc = CryptoCurrency(title: 'LTC', iconPath: 'assets/images/litecoin-ltc_icon.png', fullName: 'Litecoin', raw: 9, name: 'ltc');
  static const nano = CryptoCurrency(title: 'NANO', raw: 10, name: 'nano');
  static const trx = CryptoCurrency(title: 'TRX', iconPath: 'assets/images/trx_icon.png', fullName: 'TRON', raw: 11, name: 'trx');
  static const usdt = CryptoCurrency(title: 'USDT', iconPath: 'assets/images/usdt_icon.png', tag: 'OMNI', fullName: 'USDT', raw: 12, name: 'usdt');
  static const usdterc20 = CryptoCurrency(title: 'USDT', iconPath: 'assets/images/usdterc20_icon.png', tag: 'ETH', fullName: 'USDT', raw: 13, name: 'usdterc20');
  static const xlm = CryptoCurrency(title: 'XLM', iconPath: 'assets/images/xlm_icon.png', fullName: 'Stellar', raw: 14, name: 'xlm');
  static const xrp = CryptoCurrency(title: 'XRP', iconPath: 'assets/images/xrp_icon.png', fullName: 'Ripple', raw: 15, name: 'xrp');
  static const xhv = CryptoCurrency(title: 'XHV', iconPath: 'assets/images/xhv_logo.png', fullName: 'Haven Protocol', raw: 16, name: 'xhv');

  static const xag = CryptoCurrency(title: 'XAG', tag: 'XHV',  raw: 17, name: 'xag');
  static const xau = CryptoCurrency(title: 'XAU', tag: 'XHV', raw: 18, name: 'xau');
  static const xaud = CryptoCurrency(title: 'XAUD', tag: 'XHV', raw: 19, name: 'xaud');
  static const xbtc = CryptoCurrency(title: 'XBTC', tag: 'XHV', raw: 20, name: 'xbtc');
  static const xcad = CryptoCurrency(title: 'XCAD', tag: 'XHV', raw: 21, name: 'xcad');
  static const xchf = CryptoCurrency(title: 'XCHF', tag: 'XHV', raw: 22, name: 'xchf');
  static const xcny = CryptoCurrency(title: 'XCNY', tag: 'XHV', raw: 23, name: 'xcny');
  static const xeur = CryptoCurrency(title: 'XEUR', tag: 'XHV', raw: 24, name: 'xeur');
  static const xgbp = CryptoCurrency(title: 'XGBP', tag: 'XHV', raw: 25, name: 'xgbp');
  static const xjpy = CryptoCurrency(title: 'XJPY', tag: 'XHV', raw: 26, name: 'xjpy');
  static const xnok = CryptoCurrency(title: 'XNOK', tag: 'XHV', raw: 27, name: 'xnok');
  static const xnzd = CryptoCurrency(title: 'XNZD', tag: 'XHV', raw: 28, name: 'xnzd');
  static const xusd = CryptoCurrency(title: 'XUSD', tag: 'XHV', raw: 29, name: 'xusd');

  static const ape = CryptoCurrency(title: 'APE', iconPath: 'assets/images/ape_icon.png', tag: 'ETH', raw: 30, name: 'ape');
  static const avaxc = CryptoCurrency(title: 'AVAX', iconPath: 'assets/images/avaxc_icon.png', tag: 'C-CHAIN', raw: 31, name: 'avaxc');
  static const btt = CryptoCurrency(title: 'BTT', iconPath: 'assets/images/btt_icon.png', raw: 32, name: 'btt');
  static const bttc = CryptoCurrency(title: 'BTTC', iconPath: 'assets/images/bttbsc_icon.png',fullName: 'BitTorrent-NEW (Binance Smart Chain)', tag: 'BSC', raw: 33, name: 'bttc');
  static const doge = CryptoCurrency(title: 'DOGE', iconPath: 'assets/images/doge_icon.png', raw: 34, name: 'doge');
  static const firo = CryptoCurrency(title: 'FIRO', iconPath: 'assets/images/firo_icon.png', raw: 35, name: 'firo');
  static const usdttrc20 = CryptoCurrency(title: 'USDT', iconPath: 'assets/images/usdttrc20_icon.png', tag: 'TRX', raw: 36, name: 'usdttrc20');
  static const hbar = CryptoCurrency(title: 'HBAR', iconPath: 'assets/images/hbar_icon.png', raw: 37, name: 'hbar');
  static const sc = CryptoCurrency(title: 'SC', iconPath: 'assets/images/sc_icon.png', raw: 38, name: 'sc');
  static const sol = CryptoCurrency(title: 'SOL', iconPath: 'assets/images/sol_icon.png', raw: 39, name: 'sol');
  static const usdc = CryptoCurrency(title: 'USDC', iconPath: 'assets/images/usdc_icon.png', tag: 'ETH', raw: 40, name: 'usdc');
  static const usdcsol = CryptoCurrency(title: 'USDC', iconPath: 'assets/images/usdcsol_icon.png', tag: 'SOL', raw: 41, name: 'usdcsol');
  static const zaddr = CryptoCurrency(title: 'ZZEC', tag: 'ZEC', fullName: 'Shielded Zcash', iconPath: 'assets/images/zaddr_icon.png', raw: 42, name: 'zaddr');
  static const zec = CryptoCurrency(title: 'TZEC', tag: 'ZEC', fullName: 'Transparent Zcash', iconPath: 'assets/images/zec_icon.png', raw: 43, name: 'zec');
  static const zen = CryptoCurrency(title: 'ZEN', iconPath: 'assets/images/zen_icon.png', raw: 44, name: 'zen');
  static const xvg = CryptoCurrency(title: 'XVG', fullName: 'Verge', iconPath: 'assets/images/xvg_icon.png', raw: 45, name: 'xvg');

  static const usdcpoly = CryptoCurrency(title: 'USDC', iconPath: 'assets/images/usdc_icon.png', tag: 'POLY', raw: 46, name: 'usdcpoly');
  static const dcr = CryptoCurrency(title: 'DCR', iconPath: 'assets/images/dcr_icon.png', raw: 47, name: 'dcr');
  static const kmd = CryptoCurrency(title: 'KMD', iconPath: 'assets/images/kmd_icon.png', raw: 48, name: 'kmd');
  static const mana = CryptoCurrency(title: 'MANA', iconPath: 'assets/images/mana_icon.png', tag: 'ETH', raw: 49, name: 'mana');
  static const maticpoly = CryptoCurrency(title: 'MATIC', iconPath: 'assets/images/matic_icon.png', tag: 'POLY', raw: 50, name: 'maticpoly');
  static const matic = CryptoCurrency(title: 'MATIC', iconPath: 'assets/images/matic_icon.png', tag: 'ETH', raw: 51, name: 'matic');
  static const mkr = CryptoCurrency(title: 'MKR', iconPath: 'assets/images/mkr_icon.png', tag: 'ETH', raw: 52, name: 'mkr');
  static const near = CryptoCurrency(title: 'NEAR', iconPath: 'assets/images/near_icon.png', raw: 53, name: 'near');
  static const oxt = CryptoCurrency(title: 'OXT', iconPath: 'assets/images/oxt_icon.png', tag: 'ETH', raw: 54, name: 'oxt');
  static const paxg = CryptoCurrency(title: 'PAXG', iconPath: 'assets/images/paxg_icon.png', tag: 'ETH', raw: 55, name: 'paxg');
  static const pivx = CryptoCurrency(title: 'PIVX', iconPath: 'assets/images/pivx_icon.png', raw: 56, name: 'pivx');
  static const rune = CryptoCurrency(title: 'RUNE', iconPath: 'assets/images/rune_icon.png', raw: 57, name: 'rune');
  static const rvn = CryptoCurrency(title: 'RVN', iconPath: 'assets/images/rvn_icon.png', raw: 58, name: 'rvn');
  static const scrt = CryptoCurrency(title: 'SCRT', iconPath: 'assets/images/scrt_icon.png', raw: 59, name: 'scrt');
  static const uni = CryptoCurrency(title: 'UNI', iconPath: 'assets/images/uni_icon.png', tag: 'ETH', raw: 60, name: 'uni');
  static const stx = CryptoCurrency(title: 'STX', iconPath: 'assets/images/stx_icon.png', raw: 61, name: 'stx');

  static final Map<int, CryptoCurrency> _rawCurrencyMap =
    [...all, ...havenCurrencies].fold<Map<int, CryptoCurrency>>(<int, CryptoCurrency>{}, (acc, item) {
      acc.addAll({item.raw: item});
      return acc;
    });

  static final Map<String, CryptoCurrency> _nameCurrencyMap =
    [...all, ...havenCurrencies].fold<Map<String, CryptoCurrency>>(<String, CryptoCurrency>{}, (acc, item) {
      acc.addAll({item.name: item});
      return acc;
    });

  static CryptoCurrency deserialize({required int raw}) {

    if (CryptoCurrency._rawCurrencyMap[raw] == null) {
      final s = 'Unexpected token: $raw for CryptoCurrency deserialize';
      throw  ArgumentError.value(raw, 'raw', s);
    }
    return CryptoCurrency._rawCurrencyMap[raw]!;
  }

  static CryptoCurrency fromString(String name) {

    if (CryptoCurrency._nameCurrencyMap[name.toLowerCase()] == null) {
      final s = 'Unexpected token: $name for CryptoCurrency fromString';
      throw  ArgumentError.value(name, 'name', s);
    }
    return CryptoCurrency._nameCurrencyMap[name.toLowerCase()]!;
  }

  @override
  String toString() => title;
}
