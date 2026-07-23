import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/utils/token_utilities.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/currency.dart";
import "package:cw_core/wallet_type.dart";

Future<Currency> currencyFromSerialized(String serialized) async {
  final parts = serialized.split(".");

  switch (parts.first) {
    case "fiat":
      return FiatCurrency.deserialize(raw: parts[1]);
    case "crypto":
      return CryptoCurrency.safeParseCurrencyFromString(
        parts[1],
        tag: parts.length > 2 ? parts[2] : null,
      )!;
    case "evm":
      final walletType = switch (parts[2]) {
        "1" => WalletType.ethereum,
        "137" => WalletType.polygon,
        "8453" => WalletType.base,
        "42161" => WalletType.arbitrum,
        "56" => WalletType.bsc,
        _ => throw ArgumentError("bad chain id for evm token deserialize"),
      };
      return (await TokenUtilities.findTokenByAddress(walletType: walletType, address: parts[1]))!;
    case "sol":
      return (await TokenUtilities.findTokenByAddress(
        walletType: WalletType.solana,
        address: parts[1],
      ))!;
    case "trx":
      return (await TokenUtilities.findTokenByAddress(
        walletType: WalletType.tron,
        address: parts[1],
      ))!;
    default:
      throw ArgumentError("bad serialize string for currency");
  }
}

Future<Money> moneyFromSerialized(String serialized) async {
  final parts = serialized.split(":");
  return Money.parse(parts.last, await currencyFromSerialized(parts.first));
}
