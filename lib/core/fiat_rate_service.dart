import "dart:async";

import "package:cake_wallet/core/fiat_conversion_service.dart";
import "package:cake_wallet/entities/fiat_api_mode.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
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
      _fiatConversionStore.prices.forEach((_, __) {});
      _rateController.add(null);
    });
  }

  final FiatConversionStore _fiatConversionStore;
  final SettingsStore _settingsStore;
  final StreamController<void> _rateController = StreamController<void>.broadcast();
  final Map<CryptoCurrency, Map<FiatCurrency, double>> _customRates = {};
  late final mobx.ReactionDisposer _disposeReaction;

  Stream<void> get rateChanges => _rateController.stream;

  double? rateFor(CryptoCurrency crypto, FiatCurrency fiat) {
    if (fiat == _settingsStore.fiatCurrency) {
      return _fiatConversionStore.prices[crypto];
    }
    return _customRates[crypto]?[fiat];
  }

  Future<void> ensureRateFor(CryptoCurrency crypto, FiatCurrency fiat) async {
    if (rateFor(crypto, fiat) != null) {
      return;
    }
    try {
      final value = await FiatConversionService.fetchPrice(
        crypto: crypto,
        fiat: fiat,
        torOnly: _settingsStore.fiatApiMode == FiatApiMode.torOnly,
      );
      _customRates.putIfAbsent(crypto, () => {})[fiat] = value;
      _rateController.add(null);
    } catch (e) {
      printV("failed to fetch fiat rate for $crypto/$fiat: $e");
    }
  }

  Money? convertToFiat(Money amount, FiatCurrency to) {
    if (amount.currency is! CryptoCurrency) {
      return null;
    }
    final rate = rateFor(amount.currency as CryptoCurrency, to);
    if (rate == null || rate <= 0.0) {
      return null;
    }

    final cryptoValue = _toDisplayDouble(amount);
    final fiatValue = cryptoValue * rate;
    return Money.parse(fiatValue.toStringAsFixed(to.decimals), to);
  }

  Money? convertFromFiat(Money fiatAmount, CryptoCurrency to) {
    if (fiatAmount.currency is! FiatCurrency) {
      return null;
    }
    final rate = rateFor(to, fiatAmount.currency as FiatCurrency);
    if (rate == null || rate <= 0.0) {
      return null;
    }

    final fiatValue = _toDisplayDouble(fiatAmount);
    final cryptoValue = fiatValue / rate;
    return Money.parse(cryptoValue.toStringAsFixed(to.decimals), to);
  }

  double _toDisplayDouble(Money m) {
    final divisor = BigInt.from(10).pow(m.currency.decimals).toDouble();
    return m.amount.toDouble() / divisor;
  }

  Future<void> dispose() async {
    _disposeReaction();
    await _rateController.close();
  }
}
