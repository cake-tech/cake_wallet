import "package:cw_bitcoin/lightning/spark_token.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency_groups.dart";

class DefaultSparkTokens {
  /// USDB's identifier. Matched by identifier, not symbol/name, so a scam token can't spoof its
  /// way into the USD peg by copying the "USDB" symbol.
  static const usdbTokenIdentifier =
      "btkn1xgrvjwey5ngcagvap2dzzvsy4uk8ua9x69k82dwvt5e7ef9drm9qztux87";

  /// Whether [currency] is the default USD stablecoin (USDB), used for pricing 1:1 with USD.
  // TODO(rafael): remove after fiat conversion is enabled for the spark stable token
  static bool isDefaultStablecoin(CryptoCurrency? currency) =>
      currency is SparkToken && currency.tokenIdentifier == usdbTokenIdentifier;

  final List<SparkToken> _defaultTokens = [
    SparkToken(
      name: "USDB",
      symbol: "USDB",
      tokenIdentifier: usdbTokenIdentifier,
      decimal: 6,
      enabled: true,
      groups: const {CurrencyGroups.stablecoin},
      iconPath: "assets/new-ui/crypto_full_icons/usdb.jpg",
    ),
  ];

  List<SparkToken> initialSparkTokens(String walletName) =>
      _defaultTokens.map((token) => SparkToken.copyWith(token, walletName: walletName)).toList();
}
