import "dart:async";
import "dart:math" as math;

import "package:cake_wallet/core/fiat_conversion_service.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:mobx/mobx.dart" as mobx;

class FiatRateService {
  FiatRateService({
    required FiatConversionStore fiatConversionStore,
    required SettingsStore settingsStore,
  })  : _fiatConversionStore = fiatConversionStore,
        _settingsStore = settingsStore {
    _disposeReaction = mobx.autorun((_) {
      for (final _ in _fiatConversionStore.prices.values) {}
      _emitRateChanged();
    });

    _disposeFiatReaction = mobx.reaction(
      (_) => _settingsStore.fiatCurrency,
      (_) => _emitRateChanged(),
    );
  }

  void _emitRateChanged() {
    if (_rateController.isClosed) {
      return;
    }
    _rateController.add(null);
  }

  final FiatConversionStore _fiatConversionStore;
  final SettingsStore _settingsStore;
  final StreamController<void> _rateController = StreamController<void>.broadcast();
  final Map<CryptoCurrency, Map<FiatCurrency, double>> _customRates = {};
  final Map<CryptoCurrency, Map<FiatCurrency, Completer<void>>> _ongoingChecks = {};
  late final mobx.ReactionDisposer _disposeReaction;
  late final mobx.ReactionDisposer _disposeFiatReaction;

  Stream<void> get rateChanges => _rateController.stream;

  FiatCurrency get defaultFiat => _settingsStore.fiatCurrency;

  double? rateFor(CryptoCurrency crypto, FiatCurrency fiat) {
    if (fiat == _settingsStore.fiatCurrency) {
      final live = _fiatConversionStore.prices[crypto];
      if (live != null) {
        return live;
      }
    }
    return _customRates[crypto]?[fiat];
  }

  Future<void> ensureRateFor(CryptoCurrency crypto, FiatCurrency fiat) async {
    if (rateFor(crypto, fiat) != null) {
      return;
    }

    final isOngoingCheck = _ongoingChecks[crypto]?[fiat];
    if (isOngoingCheck != null) {
      await isOngoingCheck.future;
      return;
    }

    final completer = Completer<void>();
    _ongoingChecks.putIfAbsent(crypto, () => {})[fiat] = completer;
    try {
      await _fetchRate(crypto, fiat);
    } finally {
      _ongoingChecks[crypto]?.remove(fiat);
      if (_ongoingChecks[crypto]?.isEmpty ?? false) {
        _ongoingChecks.remove(crypto);
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> _fetchRate(CryptoCurrency crypto, FiatCurrency fiat) async {
    try {
      final value = await FiatConversionService.fetchPrice(
        crypto: crypto,
        fiat: fiat,
        torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly,
      );
      _customRates.putIfAbsent(crypto, () => {})[fiat] = value;
      _emitRateChanged();
    } catch (e) {
      printV("failed to fetch fiat rate for $crypto/$fiat: $e");
    }
  }

  bool get _isFiatDisabled => _settingsStore.fiatApiMode == FiatApiMode.disabled;

  Money? convertToFiat(Money amount, FiatCurrency to) {
    if (_isFiatDisabled || amount.currency is! CryptoCurrency) {
      return null;
    }
    final crypto = amount.currency as CryptoCurrency;
    final rate = rateFor(crypto, to);
    if (rate == null || rate <= 0.0) {
      return null;
    }

    return _pairFor(crypto, to, rate).convert(amount);
  }

  Money? convertFromFiat(Money fiatAmount, CryptoCurrency to) {
    if (_isFiatDisabled || fiatAmount.currency is! FiatCurrency) {
      return null;
    }
    final fiat = fiatAmount.currency as FiatCurrency;
    final rate = rateFor(to, fiat);
    if (rate == null || rate <= 0.0) {
      return null;
    }

    return _pairFor(to, fiat, rate).convert(fiatAmount);
  }

  ExchangeRate _pairFor(CryptoCurrency crypto, FiatCurrency fiat, double rate) {
    if (rate * rate < math.pow(10, crypto.decimals - fiat.decimals)) {
      return ExchangeRate(
        base: fiat,
        quote: Money.parse((1 / rate).toStringAsFixed(crypto.decimals), crypto),
      );
    }
    return ExchangeRate(
      base: crypto,
      quote: Money.parse(rate.toStringAsFixed(fiat.decimals), fiat),
    );
  }

  Future<void> dispose() async {
    _disposeReaction();
    _disposeFiatReaction();
    await _rateController.close();
  }
}
