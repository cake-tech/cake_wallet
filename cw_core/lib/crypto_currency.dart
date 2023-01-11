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

  // title, tag (if applicable), fullName (if unique), raw, name, iconPath
  static const xmr = CryptoCurrency(title: 'XMR', fullName: 'Monero', raw: 0, name: 'xmr', iconPath: 'assets/images/monero_icon.png');
  static const ada = CryptoCurrency(title: 'ADA', fullName: 'Cardano', raw: 1, name: 'ada', iconPath: 'assets/images/ada_icon.png');
  static const bch = CryptoCurrency(title: 'BCH', fullName: 'Bitcoin Cash', raw: 2, name: 'bch', iconPath: 'assets/images/bch_icon.png');
  static const bnb = CryptoCurrency(title: 'BNB', tag: 'BSC', fullName: 'Binance Coin', raw: 3, name: 'bnb', iconPath: 'assets/images/bnb_icon.png');
  static const btc = CryptoCurrency(title: 'BTC', fullName: 'Bitcoin', raw: 4, name: 'btc', iconPath: 'assets/images/btc.png');
  static const dai = CryptoCurrency(title: 'DAI', tag: 'ETH', fullName: 'Dai', raw: 5, name: 'dai', iconPath: 'assets/images/dai_icon.png');
  static const dash = CryptoCurrency(title: 'DASH', fullName: 'Dash', raw: 6, name: 'dash', iconPath: 'assets/images/dash_icon.png');
  static const eos = CryptoCurrency(title: 'EOS', fullName: 'EOS', raw: 7, name: 'eos', iconPath: 'assets/images/eos_icon.png');
  static const eth = CryptoCurrency(title: 'ETH', fullName: 'Ethereum', raw: 8, name: 'eth', iconPath: 'assets/images/eth_icon.png');
  static const ltc = CryptoCurrency(title: 'LTC', fullName: 'Litecoin', raw: 9, name: 'ltc', iconPath: 'assets/images/litecoin-ltc_icon.png');
  static const nano = CryptoCurrency(title: 'NANO', raw: 10, name: 'nano');
  static const trx = CryptoCurrency(title: 'TRX', fullName: 'TRON', raw: 11, name: 'trx', iconPath: 'assets/images/trx_icon.png');
  static const usdt = CryptoCurrency(title: 'USDT', tag: 'OMNI', fullName: 'USDT Tether', raw: 12, name: 'usdt', iconPath: 'assets/images/usdt_icon.png');
  static const usdterc20 = CryptoCurrency(title: 'USDT', tag: 'ETH', fullName: 'USDT Tether', raw: 13, name: 'usdterc20', iconPath: 'assets/images/usdterc20_icon.png');
  static const xlm = CryptoCurrency(title: 'XLM', fullName: 'Stellar', raw: 14, name: 'xlm', iconPath: 'assets/images/xlm_icon.png');
  static const xrp = CryptoCurrency(title: 'XRP', fullName: 'Ripple', raw: 15, name: 'xrp', iconPath: 'assets/images/xrp_icon.png');
  static const xhv = CryptoCurrency(title: 'XHV', fullName: 'Haven Protocol', raw: 16, name: 'xhv', iconPath: 'assets/images/xhv_logo.png');

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

  static const ape = CryptoCurrency(title: 'APE', tag: 'ETH', fullName: 'ApeCoin', raw: 30, name: 'ape', iconPath: 'assets/images/ape_icon.png');
  static const avaxc = CryptoCurrency(title: 'AVAX', tag: 'C-CHAIN', raw: 31, name: 'avaxc', iconPath: 'assets/images/avaxc_icon.png');
  static const btt = CryptoCurrency(title: 'BTT', tag: 'ETH', fullName: 'BitTorrent', raw: 32, name: 'btt', iconPath: 'assets/images/btt_icon.png');
  static const bttc = CryptoCurrency(title: 'BTTC', tag: 'BSC', fullName: 'BitTorrent-NEW', raw: 33, name: 'bttc', iconPath: 'assets/images/bttbsc_icon.png');
  static const doge = CryptoCurrency(title: 'DOGE', fullName: 'Dogecoin', raw: 34, name: 'doge', iconPath: 'assets/images/doge_icon.png');
  static const firo = CryptoCurrency(title: 'FIRO', raw: 35, name: 'firo', iconPath: 'assets/images/firo_icon.png');
  static const usdttrc20 = CryptoCurrency(title: 'USDT', tag: 'TRX', fullName: 'USDT Tether', raw: 36, name: 'usdttrc20', iconPath: 'assets/images/usdttrc20_icon.png');
  static const hbar = CryptoCurrency(title: 'HBAR', fullName: 'Hedera', raw: 37, name: 'hbar', iconPath: 'assets/images/hbar_icon.png', );
  static const sc = CryptoCurrency(title: 'SC', fullName: 'Siacoin', raw: 38, name: 'sc', iconPath: 'assets/images/sc_icon.png');
  static const sol = CryptoCurrency(title: 'SOL', fullName: 'Solana', raw: 39, name: 'sol', iconPath: 'assets/images/sol_icon.png');
  static const usdc = CryptoCurrency(title: 'USDC', tag: 'ETH', fullName: 'USD Coin', raw: 40, name: 'usdc', iconPath: 'assets/images/usdc_icon.png');
  static const usdcsol = CryptoCurrency(title: 'USDC', tag: 'SOL', fullName: 'USDC Coin', raw: 41, name: 'usdcsol', iconPath: 'assets/images/usdcsol_icon.png');
  static const zaddr = CryptoCurrency(title: 'ZZEC', tag: 'ZEC', fullName: 'Shielded Zcash', iconPath: 'assets/images/zaddr_icon.png', raw: 42, name: 'zaddr');
  static const zec = CryptoCurrency(title: 'TZEC', tag: 'ZEC', fullName: 'Transparent Zcash', iconPath: 'assets/images/zec_icon.png', raw: 43, name: 'zec');
  static const zen = CryptoCurrency(title: 'ZEN', fullName: 'Horizen', raw: 44, name: 'zen', iconPath: 'assets/images/zen_icon.png');
  static const xvg = CryptoCurrency(title: 'XVG', fullName: 'Verge', raw: 45, name: 'xvg', iconPath: 'assets/images/xvg_icon.png');

  static const usdcpoly = CryptoCurrency(title: 'USDC', tag: 'POLY', fullName: 'USD Coin', raw: 46, name: 'usdcpoly', iconPath: 'assets/images/usdc_icon.png');
  static const dcr = CryptoCurrency(title: 'DCR', fullName: 'Decred', raw: 47, name: 'dcr', iconPath: 'assets/images/dcr_icon.png');
  static const kmd = CryptoCurrency(title: 'KMD', fullName: 'Komodo', raw: 48, name: 'kmd', iconPath: 'assets/images/kmd_icon.png');
  static const mana = CryptoCurrency(title: 'MANA', tag: 'ETH', fullName: 'Decentraland', raw: 49, name: 'mana', iconPath: 'assets/images/mana_icon.png');
  static const maticpoly = CryptoCurrency(title: 'MATIC', tag: 'POLY', fullName: 'Polygon', raw: 50, name: 'maticpoly', iconPath: 'assets/images/matic_icon.png');
  static const matic = CryptoCurrency(title: 'MATIC', tag: 'ETH', fullName: 'Polygon', raw: 51, name: 'matic', iconPath: 'assets/images/matic_icon.png');
  static const mkr = CryptoCurrency(title: 'MKR', tag: 'ETH', fullName: 'Maker', raw: 52, name: 'mkr', iconPath: 'assets/images/mkr_icon.png');
  static const near = CryptoCurrency(title: 'NEAR', fullName: 'NEAR Protocol', raw: 53, name: 'near', iconPath: 'assets/images/near_icon.png');
  static const oxt = CryptoCurrency(title: 'OXT', tag: 'ETH', fullName: 'Orchid', raw: 54, name: 'oxt', iconPath: 'assets/images/oxt_icon.png');
  static const paxg = CryptoCurrency(title: 'PAXG', tag: 'ETH', fullName: 'Pax Gold', raw: 55, name: 'paxg', iconPath: 'assets/images/paxg_icon.png');
  static const pivx = CryptoCurrency(title: 'PIVX', raw: 56, name: 'pivx', iconPath: 'assets/images/pivx_icon.png');
  static const rune = CryptoCurrency(title: 'RUNE', fullName: 'Thorchain', raw: 57, name: 'rune', iconPath: 'assets/images/rune_icon.png');
  static const rvn = CryptoCurrency(title: 'RVN', fullName: 'Ravencoin', raw: 58, name: 'rvn', iconPath: 'assets/images/rvn_icon.png');
  static const scrt = CryptoCurrency(title: 'SCRT', fullName: 'Secret Network', raw: 59, name: 'scrt', iconPath: 'assets/images/scrt_icon.png');
  static const uni = CryptoCurrency(title: 'UNI', tag: 'ETH', fullName: 'Uniswap', raw: 60, name: 'uni', iconPath: 'assets/images/uni_icon.png');
  static const stx = CryptoCurrency(title: 'STX', fullName: 'Stacks', raw: 61, name: 'stx', iconPath: 'assets/images/stx_icon.png');

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
