import "dart:async";

import "package:cake_wallet/core/fiat_conversion_service.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:mobx/mobx.dart";

part "fiat_conversion_store.g.dart";

typedef FiatPriceFetcher = Future<double> Function({
  required CryptoCurrency crypto,
  required FiatCurrency fiat,
  required bool torOnly,
});

class FiatConversionStore = FiatConversionStoreBase with _$FiatConversionStore;

abstract class FiatConversionStoreBase with Store {
  FiatConversionStoreBase({
    required SettingsStore settingsStore,
    FiatPriceFetcher fetchPrice = FiatConversionService.fetchPrice,
  })  : _settingsStore = settingsStore,
        _fetchPrice = fetchPrice,
        _fiat = settingsStore.fiatCurrency,
        _mode = settingsStore.fiatApiMode,
        prices = ObservableMap<CryptoCurrency, double>() {
    _settingsDisposer = reaction(
      (_) => (_settingsStore.fiatCurrency, _settingsStore.fiatApiMode),
      (_) => _updateContext(),
    );
  }

  final SettingsStore _settingsStore;
  final FiatPriceFetcher _fetchPrice;
  final _currencies = <CryptoCurrency>{};
  final _pending = <CryptoCurrency, Future<void>>{};
  late final ReactionDisposer _settingsDisposer;
  FiatCurrency _fiat;
  FiatApiMode _mode;
  bool _disposed = false;

  @observable
  int _generation = 0;

  int get generation => _generation;

  @observable
  ObservableMap<CryptoCurrency, double> prices;

  Future<void> fetchPrice(CryptoCurrency currency, {bool force = false}) {
    if (_disposed) {
      return Future.value();
    }
    // A caller may request a price inside the action that changes the settings.
    _updateContext();
    _currencies.add(currency);
    if (_mode == FiatApiMode.disabled) {
      return Future.value();
    }
    final pending = _pending[currency];
    if (pending != null) {
      return pending;
    }
    final cached = prices[currency];
    if (!force && cached != null && cached.isFinite && cached > 0) {
      return Future.value();
    }

    final request = _loadPrice(currency, _generation, _fiat, _mode);
    _pending[currency] = request;
    return request;
  }

  void _updateContext() {
    if (_disposed ||
        (_fiat == _settingsStore.fiatCurrency && _mode == _settingsStore.fiatApiMode)) {
      return;
    }
    _currencies.addAll(prices.keys);
    _pending.clear();
    runInAction(() {
      _fiat = _settingsStore.fiatCurrency;
      _mode = _settingsStore.fiatApiMode;
      _generation++;
      prices.clear();
    });
    if (_mode != FiatApiMode.disabled) {
      for (final currency in _currencies.toList()) {
        unawaited(fetchPrice(currency));
      }
    }
  }

  Future<void> _loadPrice(
    CryptoCurrency currency,
    int generation,
    FiatCurrency fiat,
    FiatApiMode mode,
  ) async {
    try {
      final price = await Future.sync(
        () => _fetchPrice(
          crypto: currency,
          fiat: fiat,
          torOnly: mode == FiatApiMode.torOnly,
        ),
      );
      if (!_disposed &&
          generation == _generation &&
          fiat == _settingsStore.fiatCurrency &&
          mode == _settingsStore.fiatApiMode &&
          price.isFinite &&
          price > 0) {
        runInAction(() => prices[currency] = price);
      }
    } catch (e) {
      printV("Failed to update $currency fiat price: $e");
    } finally {
      if (generation == _generation) {
        unawaited(_pending.remove(currency));
      }
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _settingsDisposer();
    runInAction(() => _generation++);
    _pending.clear();
  }
}
