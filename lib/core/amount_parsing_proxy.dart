import 'package:cake_wallet/entities/bitcoin_amount_display_mode.dart';
import 'package:cake_wallet/src/screens/wallet_connect/utils/string_parsing.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/currency.dart';
import 'package:cw_core/utils/print_verbose.dart';

class AmountParsingProxy {
  final BitcoinAmountDisplayMode displayMode;

  const AmountParsingProxy(this.displayMode);

  /// [getCryptoInputAmount] turns the input [amount] into the canonical representation of [cryptoCurrency]
  String getCanonicalCryptoAmount(String amount, CryptoCurrency cryptoCurrency) {
    if (useSatoshi(cryptoCurrency) && amount.isNotEmpty) {
      return cryptoCurrency.formatAmount(BigInt.tryParse(amount) ?? BigInt.zero);
    }

    return amount;
  }

  /// [getCryptoOutputAmount] turns the input [amount] into the preferred representation of [cryptoCurrency]
  String getDisplayCryptoAmount(String amount, CryptoCurrency cryptoCurrency) {
    try {
      if (useSatoshi(cryptoCurrency) && amount.isNotEmpty) {
        return cryptoCurrency
            .parseAmount(amount.withMaxDecimals(cryptoCurrency.decimals))
            .toStringWithPrecision(useBaseUnit: true);
      }

      return amount.withMaxDecimals(cryptoCurrency.decimals);
    } catch (_) {
      printV(
          "failed to parse amount $amount for currency ${cryptoCurrency.title}, falling back to showing unparsed");
      return amount;
    }
  }

  String getDisplayCryptoString(int amount, CryptoCurrency cryptoCurrency) =>
      asDisplayString(Money.fromInt(amount, cryptoCurrency));

  /// [getDisplayCryptoString] turns the input [amount] into the preferred representation of [cryptoCurrency]
  ///
  /// if [displayMode] is [BitcoinAmountDisplayMode.satoshi] it returns 1 BTC as 100000000
  /// if [displayMode] is [BitcoinAmountDisplayMode.bitcoin] it returns 1 BTC as 1
  /// hardcoding fractionalDigits to 8 as it's a display string, so no need to show more than that
  String asDisplayString(Money amount) =>
      amount.toStringWithPrecision(useBaseUnit: useSatoshi(amount.currency), fractionalDigits: 8);

  /// [asDisplayStringWithSymbol] turns the input [amount] into the preferred representation of
  /// [cryptoCurrency] following the symbol of the unit
  ///
  /// if [displayMode] is [BitcoinAmountDisplayMode.satoshi] it returns 1 BTC as 100000000 sats
  /// if [displayMode] is [BitcoinAmountDisplayMode.bitcoin] it returns 1 BTC as 1 BTC
  /// hardcoding fractionalDigits to 8 as it's a display string, so no need to show more than that
  String asDisplayStringWithSymbol(Money amount) =>
      amount.toStringWithSymbol(useBaseUnit: useSatoshi(amount.currency), fractionalDigits: 8);

  /// [parseCryptoString] turns the the display representation [string] into `Money` with [cryptoCurrency]
  Money parseCryptoString(String amount, CryptoCurrency cryptoCurrency) =>
      Money.parse(amount, cryptoCurrency, isBaseUnit: useSatoshi(cryptoCurrency));

  /// [tryParseCryptoString] tries to turn the display representation [string] into `Money` with [cryptoCurrency]
  Money? tryParseCryptoString(String amount, CryptoCurrency cryptoCurrency) =>
      Money.tryParse(amount, cryptoCurrency, isBaseUnit: useSatoshi(cryptoCurrency));

  /// [getCryptoSymbol] returns the correct Symbol related to the presentation
  String getCryptoSymbol(CryptoCurrency cryptoCurrency) =>
      useSatoshi(cryptoCurrency) ? "sats" : cryptoCurrency.title.safeSubString(0, 8);

  bool useSatoshi(Currency cryptoCurrency) =>
      ([CryptoCurrency.btc, CryptoCurrency.btcln].contains(cryptoCurrency) &&
          displayMode == BitcoinAmountDisplayMode.satoshi) ||
      (CryptoCurrency.btcln == cryptoCurrency &&
          displayMode == BitcoinAmountDisplayMode.satoshiForLightning);
}
