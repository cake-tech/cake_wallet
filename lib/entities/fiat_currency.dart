import 'package:cw_core/enumerable_item.dart';

class FiatCurrency extends EnumerableItem<String> with Serializable<String> {
  const FiatCurrency({String symbol, this.countryCode}) : super(title: symbol, raw: symbol);

  final String countryCode;

  static List<FiatCurrency> get all => _all.values.toList();

  static const aud = FiatCurrency(symbol: 'AUD', countryCode: "aus");
  static const bgn = FiatCurrency(symbol: 'BGN');
  static const brl = FiatCurrency(symbol: 'BRL', countryCode: "bra");
  static const cad = FiatCurrency(symbol: 'CAD', countryCode: "cad");
  static const chf = FiatCurrency(symbol: 'CHF', countryCode: "che");
  static const cny = FiatCurrency(symbol: 'CNY', countryCode: "chn");
  static const czk = FiatCurrency(symbol: 'CZK', countryCode: "czk");
  static const eur = FiatCurrency(symbol: 'EUR', countryCode: "eur");
  static const dkk = FiatCurrency(symbol: 'DKK', countryCode: "dnk");
  static const gbp = FiatCurrency(symbol: 'GBP', countryCode: "gbr");
  static const hkd = FiatCurrency(symbol: 'HKD');
  static const hrk = FiatCurrency(symbol: 'HRK', countryCode: "hrv");
  static const huf = FiatCurrency(symbol: 'HUF', countryCode: "hun");
  static const idr = FiatCurrency(symbol: 'IDR', countryCode: "idn");
  static const ils = FiatCurrency(symbol: 'ILS', countryCode: "isr");
  static const inr = FiatCurrency(symbol: 'INR', countryCode: "ind");
  static const isk = FiatCurrency(symbol: 'ISK', countryCode: "isl");
  static const jpy = FiatCurrency(symbol: 'JPY', countryCode: "jpn");
  static const krw = FiatCurrency(symbol: 'KRW', countryCode: "kor");
  static const mxn = FiatCurrency(symbol: 'MXN', countryCode: "mex");
  static const myr = FiatCurrency(symbol: 'MYR', countryCode: "mys");
  static const nok = FiatCurrency(symbol: 'NOK', countryCode: "nor");
  static const nzd = FiatCurrency(symbol: 'NZD', countryCode: "nzl");
  static const php = FiatCurrency(symbol: 'PHP', countryCode: "phl");
  static const pln = FiatCurrency(symbol: 'PLN', countryCode: "pol");
  static const ron = FiatCurrency(symbol: 'RON', countryCode: "rou");
  static const rub = FiatCurrency(symbol: 'RUB', countryCode: "rus");
  static const sek = FiatCurrency(symbol: 'SEK', countryCode: "swe");
  static const sgd = FiatCurrency(symbol: 'SGD', countryCode: "sgp");
  static const thb = FiatCurrency(symbol: 'THB', countryCode: "tha");
  static const usd = FiatCurrency(symbol: 'USD', countryCode: "usa");
  static const zar = FiatCurrency(symbol: 'ZAR', countryCode: "saf");
  static const vef = FiatCurrency(symbol: 'VEF', countryCode: "ven");

  static final _all = {
    FiatCurrency.aud.raw: FiatCurrency.aud,
    FiatCurrency.bgn.raw: FiatCurrency.bgn,
    FiatCurrency.brl.raw: FiatCurrency.brl,
    FiatCurrency.cad.raw: FiatCurrency.cad,
    FiatCurrency.chf.raw: FiatCurrency.chf,
    FiatCurrency.cny.raw: FiatCurrency.cny,
    FiatCurrency.czk.raw: FiatCurrency.czk,
    FiatCurrency.eur.raw: FiatCurrency.eur,
    FiatCurrency.dkk.raw: FiatCurrency.dkk,
    FiatCurrency.gbp.raw: FiatCurrency.gbp,
    FiatCurrency.hkd.raw: FiatCurrency.hkd,
    FiatCurrency.hrk.raw: FiatCurrency.hrk,
    FiatCurrency.huf.raw: FiatCurrency.huf,
    FiatCurrency.idr.raw: FiatCurrency.idr,
    FiatCurrency.ils.raw: FiatCurrency.ils,
    FiatCurrency.inr.raw: FiatCurrency.inr,
    FiatCurrency.isk.raw: FiatCurrency.isk,
    FiatCurrency.jpy.raw: FiatCurrency.jpy,
    FiatCurrency.krw.raw: FiatCurrency.krw,
    FiatCurrency.mxn.raw: FiatCurrency.mxn,
    FiatCurrency.myr.raw: FiatCurrency.myr,
    FiatCurrency.nok.raw: FiatCurrency.nok,
    FiatCurrency.nzd.raw: FiatCurrency.nzd,
    FiatCurrency.php.raw: FiatCurrency.php,
    FiatCurrency.pln.raw: FiatCurrency.pln,
    FiatCurrency.ron.raw: FiatCurrency.ron,
    FiatCurrency.rub.raw: FiatCurrency.rub,
    FiatCurrency.sek.raw: FiatCurrency.sek,
    FiatCurrency.sgd.raw: FiatCurrency.sgd,
    FiatCurrency.thb.raw: FiatCurrency.thb,
    FiatCurrency.usd.raw: FiatCurrency.usd,
    FiatCurrency.zar.raw: FiatCurrency.zar,
    FiatCurrency.vef.raw: FiatCurrency.vef
  };

  static FiatCurrency deserialize({String raw}) => _all[raw];

  @override
  bool operator ==(Object other) => other is FiatCurrency && other.raw == raw;

  @override
  int get hashCode => raw.hashCode ^ title.hashCode;
}
