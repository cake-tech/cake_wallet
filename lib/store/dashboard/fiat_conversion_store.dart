import "package:cake_wallet/core/fiat_conversion_service.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import 'package:cw_core/crypto_currency.dart';
import "package:cw_core/currency.dart";
import 'package:mobx/mobx.dart';

part 'fiat_conversion_store.g.dart';

class FiatConversionStore = FiatConversionStoreBase with _$FiatConversionStore;

abstract class FiatConversionStoreBase with Store {
  FiatConversionStoreBase(this._settingsStore) : prices = ObservableMap<CryptoCurrency, double>();

  final SettingsStore _settingsStore;

  @observable
  ObservableMap<CryptoCurrency, double> prices;

  // TODO refactor after charts is merged
  Future<Money> convert(Money amount, Currency target) async {
    final (crypto, fiat) = switch ((amount.currency, target)) {
      (final CryptoCurrency crypto, final FiatCurrency fiat) => (crypto, fiat),
      (final FiatCurrency fiat, final CryptoCurrency crypto) => (crypto, fiat),
      _ => throw ArgumentError("for now, only fiat <-> crypto conversions are supported"),
    };

    final price = await _price(crypto, fiat);
    if (price == null) {
      return Money.zero(target);
    }

    final rate = ExchangeRate(
      base: crypto,
      quote: Money.parse(_plainDecimal(price), fiat, strictParsing: false),
    );
    return rate.convert(amount).copyWith(currency: target);
  }

  Future<double?> _price(CryptoCurrency crypto, FiatCurrency fiat) async {
    final mode = _settingsStore.fiatApiMode;
    if (mode == FiatApiMode.disabled) {
      return null;
    }

    final cached = prices[crypto];
    if (cached != null && cached > 0) {
      return cached;
    }

    final price = await FiatConversionService.fetchPrice(
      crypto: crypto,
      fiat: fiat,
      torOnly: mode == FiatApiMode.torOnly,
    );

    if (price <= 0) {
      return null;
    }

    prices[crypto] = price;
    return price;
  }

  static String _plainDecimal(double value) {
    final source = value.toString();
    return source.contains("e") ? value.toStringAsFixed(20) : source;
  }
}
