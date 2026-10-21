import "dart:async";

import "package:cake_wallet/core/fiat_conversion_service.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:mobx/mobx.dart" as mobx;

class FiatRateService {
  FiatRateService({
    required FiatConversionStore fiatConversionStore,
    required SettingsStore settingsStore,
  })  : _fiatConversionStore = fiatConversionStore,
        _settingsStore = settingsStore {
    _disposeReaction = mobx.autorun((_) {
      final fiat = _settingsStore.fiatCurrency;
      final _ = _fiatConversionStore.prices.values.toList();
      _notify(fiat);
    });
  }

  final SettingsStore _settingsStore;
  final FiatConversionStore _fiatConversionStore;
  late final mobx.ReactionDisposer _disposeReaction;
  final StreamController<FiatCurrency> _rateChangesController =
      StreamController<FiatCurrency>.broadcast();

  FiatCurrency get currentFiat => _settingsStore.fiatCurrency;
  Stream<FiatCurrency> get rateChanges => _rateChangesController.stream;

  final Map<(CryptoCurrency, FiatCurrency), ExchangeRate> _fetchedRates = {};
  final Map<(CryptoCurrency, FiatCurrency), Future<void>> _inflightFetches = {};

  void _notify(FiatCurrency fiat) {
    if (_rateChangesController.isClosed) {
      return;
    }
    _rateChangesController.add(fiat);
  }

  CryptoCurrency _pricedAs(CryptoCurrency crypto) =>
      crypto == CryptoCurrency.btcln ? CryptoCurrency.btc : crypto;

  ExchangeRate? _rateFor(CryptoCurrency crypto, FiatCurrency fiat) {
    final priced = _pricedAs(crypto);
    if (fiat == _settingsStore.fiatCurrency) {
      final live = _fiatConversionStore.prices[priced];
      if (live != null) {
        final pair = ExchangeRate.tryFromDouble(base: priced, quoteCurrency: fiat, rate: live);
        if (pair != null) {
          return pair;
        }
      }
    }

    return _fetchedRates[(priced, fiat)];
  }

  Future<void> ensureRateFor(CryptoCurrency crypto, FiatCurrency fiat) {
    final priced = _pricedAs(crypto);
    if (_rateFor(priced, fiat) != null) {
      return Future<void>.value();
    }

    final key = (priced, fiat);
    final pending = _inflightFetches[key];
    if (pending != null) {
      return pending;
    }

    final fetch = _fetchRate(priced, fiat).whenComplete(() {
      _inflightFetches.remove(key);
    });
    _inflightFetches[key] = fetch;
    return fetch;
  }

  Future<void> _fetchRate(CryptoCurrency crypto, FiatCurrency fiat) async {
    try {
      final rate = ExchangeRate.tryFromDouble(
        base: crypto,
        quoteCurrency: fiat,
        rate: await FiatConversionService.fetchPrice(
          crypto: crypto,
          fiat: fiat,
          torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly,
        ),
      );

      if (rate == null) {
        printV("fiat rate fetch returned no price for $crypto/$fiat");
        return;
      }

      _fetchedRates[(crypto, fiat)] = rate;
      _notify(_settingsStore.fiatCurrency);
    } catch (e) {
      printV("failed to fetch fiat rate for $crypto/$fiat: $e");
    }
  }

  Money? convert(Money amount, Currency to) {
    if (_settingsStore.fiatApiMode == FiatApiMode.disabled) {
      return null;
    }

    final from = amount.currency;
    CryptoCurrency? crypto;
    FiatCurrency? fiat;

    if (from is CryptoCurrency && to is FiatCurrency) {
      crypto = from;
      fiat = to;
    }
    if (from is FiatCurrency && to is CryptoCurrency) {
      crypto = to;
      fiat = from;
    }
    if (crypto == null || fiat == null) {
      return null;
    }

    final rate = _rateFor(crypto, fiat);
    if (rate == null) {
      return null;
    }

    if (from == CryptoCurrency.btcln) {
      return rate.convert(Money(amount.amount, CryptoCurrency.btc));
    }
    final converted = rate.convert(amount);
    if (to == CryptoCurrency.btcln) {
      return Money(converted.amount, CryptoCurrency.btcln);
    }
    return converted;
  }

  Future<void> dispose() async {
    _disposeReaction();
    await _rateChangesController.close();
  }
}
