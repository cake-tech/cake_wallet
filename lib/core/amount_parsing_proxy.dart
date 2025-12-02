import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cw_core/crypto_currency.dart';

class AmountParsingProxy {
  final BitcoinAmountDisplayMode displayMode;

  const AmountParsingProxy(this.displayMode);

  /// [getCryptoInputAmount] turns the input [amount] into the canonical representation of [cryptoCurrency]
  String getCryptoInputAmount(String amount, CryptoCurrency cryptoCurrency) {
    if (_requiresConversion(cryptoCurrency)) {
      return cryptoCurrency.formatAmount(BigInt.parse(amount));
    }

    return amount;
  }

  /// [getCryptoOutputAmount] turns the input [amount] into the preferred representation of [cryptoCurrency]
  String getCryptoOutputAmount(String amount, CryptoCurrency cryptoCurrency) {
    if (_requiresConversion(cryptoCurrency)) {
      return cryptoCurrency.parseAmount(amount).toString();
    }

    return amount;
  }

  bool _requiresConversion(CryptoCurrency cryptoCurrency) =>
      ([CryptoCurrency.btc, CryptoCurrency.btcln].contains(cryptoCurrency) &&
          displayMode == BitcoinAmountDisplayMode.satoshi) ||
      (CryptoCurrency.btcln == cryptoCurrency &&
          displayMode == BitcoinAmountDisplayMode.satoshiForLightning);
}
