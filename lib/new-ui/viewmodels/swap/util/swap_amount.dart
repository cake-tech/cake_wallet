import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class SwapAmount {
  SwapAmount({required this.cryptoAmount, required this.fiatAmount}) {
    if (cryptoAmount.currency is! CryptoCurrency) {
      throw ArgumentError("cryptoAmount must be Money with CryptoCurrency");
    }
    if (fiatAmount.currency is! FiatCurrency) {
      throw ArgumentError("fiatAmount must be Money with FiatCurrency");
    }
  }

  final Money cryptoAmount;
  final Money fiatAmount;

  CryptoCurrency get currency => cryptoAmount.currency as CryptoCurrency;
}

class SwapAmountFactory {
  SwapAmountFactory({required FiatConversionStore fcs, required SettingsStore settingsStore})
      : _fcs = fcs,
        _settingsStore = settingsStore;

  final FiatConversionStore _fcs;
  final SettingsStore _settingsStore;

  SwapAmount getSwapAmount(Money amount, CryptoCurrency crypto) {
    final fiat = _settingsStore.fiatCurrency;

    if (amount.currency is FiatCurrency) {
      return SwapAmount(cryptoAmount: _fcs.convert(amount, crypto), fiatAmount: amount);
    } else {
      return SwapAmount(cryptoAmount: amount, fiatAmount: _fcs.convert(amount, fiat));
    }
  }
}
