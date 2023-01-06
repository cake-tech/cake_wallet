import 'package:cw_core/enumerable_item.dart';

class FiatCurrency extends EnumerableItem<String> with Serializable<String> {
  const FiatCurrency({required String symbol, required this.countryCode, required this.fullName}) : super(title: symbol, raw: symbol);

  final String countryCode;
  final String fullName;

  static List<FiatCurrency> get all => _all.values.toList();

  static List<FiatCurrency> get currenciesAvailableToBuyWith =>
      [aud, brl, cad, chf, czk, eur, dkk, gbp, hkd, ils, jpy, krw, mxn, myr, nok, nzd, pln, sek, sgd, thb, usd, zar, idn];

  static const aud = FiatCurrency(symbol: 'AUD', countryCode: "aus", fullName: "Australian Dollar");
  static const bgn = FiatCurrency(symbol: 'BGN', countryCode: "bgr", fullName: "Bulgarian Lev");
  static const brl = FiatCurrency(symbol: 'BRL', countryCode: "bra", fullName: "Brazilian Real");
  static const cad = FiatCurrency(symbol: 'CAD', countryCode: "cad", fullName: "Canadian Dollar");
  static const chf = FiatCurrency(symbol: 'CHF', countryCode: "che", fullName: "Swiss Franc");
  static const cny = FiatCurrency(symbol: 'CNY', countryCode: "chn", fullName: "Chinese Yuan");
  static const czk = FiatCurrency(symbol: 'CZK', countryCode: "czk", fullName: "Czech Koruna");
  static const eur = FiatCurrency(symbol: 'EUR', countryCode: "eur", fullName: "Euro");
  static const dkk = FiatCurrency(symbol: 'DKK', countryCode: "dnk", fullName: "Danish Krone");
  static const gbp = FiatCurrency(symbol: 'GBP', countryCode: "gbr", fullName: "Pound sterling");
  static const hkd = FiatCurrency(symbol: 'HKD', countryCode: "hkg", fullName: "Hong Kong Dollar");
  static const hrk = FiatCurrency(symbol: 'HRK', countryCode: "hrv", fullName: "Croatian Kuna");
  static const huf = FiatCurrency(symbol: 'HUF', countryCode: "hun", fullName: "Hungarian Forint");
  static const idr = FiatCurrency(symbol: 'IDR', countryCode: "idn", fullName: "Indonesian Rupiah");
  static const ils = FiatCurrency(symbol: 'ILS', countryCode: "isr", fullName: "Israeli New Shekel");
  static const inr = FiatCurrency(symbol: 'INR', countryCode: "ind", fullName: "Indian Rupee");
  static const isk = FiatCurrency(symbol: 'ISK', countryCode: "isl", fullName: "Icelandic Króna");
  static const jpy = FiatCurrency(symbol: 'JPY', countryCode: "jpn", fullName: "Japanese Yen equals");
  static const krw = FiatCurrency(symbol: 'KRW', countryCode: "kor", fullName: "South Korean won");
  static const mxn = FiatCurrency(symbol: 'MXN', countryCode: "mex", fullName: "Mexican Peso");
  static const myr = FiatCurrency(symbol: 'MYR', countryCode: "mys", fullName: "Malaysian Ringgit");
  static const nok = FiatCurrency(symbol: 'NOK', countryCode: "nor", fullName: "Norwegian Krone");
  static const nzd = FiatCurrency(symbol: 'NZD', countryCode: "nzl", fullName: "New Zealand Dollar");
  static const php = FiatCurrency(symbol: 'PHP', countryCode: "phl", fullName: "Philippine peso");
  static const pln = FiatCurrency(symbol: 'PLN', countryCode: "pol", fullName: "Poland złoty");
  static const ron = FiatCurrency(symbol: 'RON', countryCode: "rou", fullName: "Romanian Leu");
  static const rub = FiatCurrency(symbol: 'RUB', countryCode: "rus", fullName: "Russian Ruble");
  static const sek = FiatCurrency(symbol: 'SEK', countryCode: "swe", fullName: "Swedish Krona");
  static const sgd = FiatCurrency(symbol: 'SGD', countryCode: "sgp", fullName: "Singapore Dollar");
  static const thb = FiatCurrency(symbol: 'THB', countryCode: "tha", fullName: "Thai Baht");
  static const usd = FiatCurrency(symbol: 'USD', countryCode: "usa", fullName: "United States Dollar");
  static const zar = FiatCurrency(symbol: 'ZAR', countryCode: "saf", fullName: "South African Rand");
  static const vef = FiatCurrency(symbol: 'VEF', countryCode: "ven", fullName: "Venezuelan Bolívar");

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

  static FiatCurrency deserialize({required String raw}) => _all[raw]!;

  @override
  bool operator ==(Object other) => other is FiatCurrency && other.raw == raw;

  @override
  int get hashCode => raw.hashCode ^ title.hashCode;
}
