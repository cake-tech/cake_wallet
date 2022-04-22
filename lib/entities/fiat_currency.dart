import 'package:cw_core/enumerable_item.dart';

class FiatCurrency extends EnumerableItem<String> with Serializable<String> {
  const FiatCurrency({String symbol}) : super(title: symbol, raw: symbol);

  static List<FiatCurrency> get all => _all.values.toList();

  static const aud = FiatCurrency(symbol: 'AUD');
  static const bgn = FiatCurrency(symbol: 'BGN');
  static const brl = FiatCurrency(symbol: 'BRL');
  static const cad = FiatCurrency(symbol: 'CAD');
  static const chf = FiatCurrency(symbol: 'CHF');
  static const cny = FiatCurrency(symbol: 'CNY');
  static const czk = FiatCurrency(symbol: 'CZK');
  static const eur = FiatCurrency(symbol: 'EUR');
  static const dkk = FiatCurrency(symbol: 'DKK');
  static const gbp = FiatCurrency(symbol: 'GBP');
  static const hkd = FiatCurrency(symbol: 'HKD');
  static const hrk = FiatCurrency(symbol: 'HRK');
  static const huf = FiatCurrency(symbol: 'HUF');
  static const idr = FiatCurrency(symbol: 'IDR');
  static const ils = FiatCurrency(symbol: 'ILS');
  static const inr = FiatCurrency(symbol: 'INR');
  static const isk = FiatCurrency(symbol: 'ISK');
  static const jpy = FiatCurrency(symbol: 'JPY');
  static const krw = FiatCurrency(symbol: 'KRW');
  static const mxn = FiatCurrency(symbol: 'MXN');
  static const myr = FiatCurrency(symbol: 'MYR');
  static const nok = FiatCurrency(symbol: 'NOK');
  static const nzd = FiatCurrency(symbol: 'NZD');
  static const php = FiatCurrency(symbol: 'PHP');
  static const pln = FiatCurrency(symbol: 'PLN');
  static const ron = FiatCurrency(symbol: 'RON');
  static const rub = FiatCurrency(symbol: 'RUB');
  static const sek = FiatCurrency(symbol: 'SEK');
  static const sgd = FiatCurrency(symbol: 'SGD');
  static const thb = FiatCurrency(symbol: 'THB');
  static const usd = FiatCurrency(symbol: 'USD');
  static const zar = FiatCurrency(symbol: 'ZAR');
  static const vef = FiatCurrency(symbol: 'VEF');

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
