import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cw_core/crypto_currency.dart';

class AmountParsingProxy {
  final BitcoinAmountDisplayMode displayMode;

  const AmountParsingProxy(this.displayMode);

  /// [getCryptoInputAmount] turns the input [amount] into the canonical representation of [cryptoCurrency]
  String getCryptoInputAmount(String amount, CryptoCurrency cryptoCurrency) {
    if (useSatoshi(cryptoCurrency) && amount.isNotEmpty) {
      return cryptoCurrency.formatAmount(BigInt.parse(amount));
    }

    return amount;
  }

  /// [getCryptoOutputAmount] turns the input [amount] into the preferred representation of [cryptoCurrency]
  String getCryptoOutputAmount(String amount, CryptoCurrency cryptoCurrency) {
    if (useSatoshi(cryptoCurrency) && amount.isNotEmpty) {
      return cryptoCurrency.parseAmount(amount).toString();
    }

    return amount;
  }

  /// [getCryptoStringRepresentation] turns the input [amount] into the preferred representation of [cryptoCurrency]
  String getCryptoString(int amount, CryptoCurrency cryptoCurrency) {
    if (useSatoshi(cryptoCurrency)) {
      return "$amount";
    }

    return cryptoCurrency.formatAmount(BigInt.from(amount));
  }

  /// [getCryptoStringFromDouble] turns the input [amount] into the preferred representation of [cryptoCurrency] and
  String getCryptoStringFromDouble(double amount, CryptoCurrency cryptoCurrency) {
    if (useSatoshi(cryptoCurrency)) {
      return "$amount";
    }

    return cryptoCurrency.formatAmount(BigInt.from(amount));
  }

  /// [parseCryptoString] turns the input [string] into a `BigInt` presentation of the [cryptoCurrency]
  BigInt parseCryptoString(String amount, CryptoCurrency cryptoCurrency) {
    if (useSatoshi(cryptoCurrency)) {
      return BigInt.parse(amount);
    }

    return cryptoCurrency.parseAmount(amount);
  }

  /// [getCryptoSymbol] returns the correct Symbol related to the presentation
  String getCryptoSymbol(CryptoCurrency cryptoCurrency) =>
      useSatoshi(cryptoCurrency) ? "SATS" : cryptoCurrency.title;

  bool useSatoshi(CryptoCurrency cryptoCurrency) =>
      ([CryptoCurrency.btc, CryptoCurrency.btcln].contains(cryptoCurrency) &&
          displayMode == BitcoinAmountDisplayMode.satoshi) ||
      (CryptoCurrency.btcln == cryptoCurrency &&
          displayMode == BitcoinAmountDisplayMode.satoshiForLightning);
}
