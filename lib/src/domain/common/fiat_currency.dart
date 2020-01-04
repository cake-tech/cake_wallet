import 'package:cake_wallet/src/domain/common/enumerable_item.dart';

class FiatCurrency extends EnumerableItem<String> with Serializable<String> {
  static const all = [
    FiatCurrency.aud,
    FiatCurrency.bgn,
    FiatCurrency.brl,
    FiatCurrency.cad,
    FiatCurrency.chf,
    FiatCurrency.cny,
    FiatCurrency.czk,
    FiatCurrency.eur,
    FiatCurrency.dkk,
    FiatCurrency.gbp,
    FiatCurrency.hkd,
    FiatCurrency.hrk,
    FiatCurrency.huf,
    FiatCurrency.idr,
    FiatCurrency.ils,
    FiatCurrency.inr,
    FiatCurrency.isk,
    FiatCurrency.jpy,
    FiatCurrency.krw,
    FiatCurrency.mxn,
    FiatCurrency.myr,
    FiatCurrency.nok,
    FiatCurrency.nzd,
    FiatCurrency.php,
    FiatCurrency.pln,
    FiatCurrency.ron,
    FiatCurrency.rub,
    FiatCurrency.sek,
    FiatCurrency.sgd,
    FiatCurrency.thb,
    FiatCurrency.usd,
    FiatCurrency.zar,
    FiatCurrency.vef
  ];

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

  const FiatCurrency({String symbol}) : super(title: symbol, raw: symbol);

  operator ==(o) => o is FiatCurrency && o.raw == raw;

  @override
  int get hashCode => raw.hashCode ^ title.hashCode;
}
