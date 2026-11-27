import "package:cake_wallet/exchange/provider/near_intents/near_intents_api_schema.dart";
import "package:cake_wallet/exchange/provider/near_intents/near_intents_exchange_provider.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/tron_token.dart";
import "package:flutter_test/flutter_test.dart";

NearIntentsToken _token(String assetId, String blockchain, String symbol, String? contract) =>
    NearIntentsToken(
      assetId: assetId,
      decimals: 6,
      blockchain: blockchain,
      symbol: symbol,
      price: 1,
      priceUpdatedAt: DateTime(2026),
      contractAddress: contract,
    );

void main() {
  final provider = NearIntentsExchangeProvider();

  group("currencyToNearAssetId", () {
    test("picks Tether's USDT on NEAR even if a bridged USDT is listed first", () {
      final tokens = [
        _token("nep141:miden-0x5cb7.omft.near", "near", "USDT", "miden-0x5cb7.omft.near"),
        _token("nep141:usdt.tether-token.near", "near", "USDT", "usdt.tether-token.near"),
      ];

      expect(
        provider.currencyToNearAssetId(CryptoCurrency.usdtNear, tokens)?.assetId,
        "nep141:usdt.tether-token.near",
      );
    });

    test("does not pin another network's USDT token to NEAR's USDT", () {
      final tronUsdt = TronToken(
        name: "Tether USD",
        symbol: "USDT",
        contractAddress: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t",
        decimal: 6,
        tag: "TRX",
      );
      final tokens = [
        _token("nep141:usdt.tether-token.near", "near", "USDT", "usdt.tether-token.near"),
        _token("nep141:tron-d28a.omft.near", "tron", "USDT", "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"),
      ];

      expect(
        provider.currencyToNearAssetId(tronUsdt, tokens)?.assetId,
        "nep141:tron-d28a.omft.near",
      );
    });

    test("maps USDT on Optimism to USDT0, not the legacy USDT", () {
      final tokens = [
        _token("nep245:op-legacy", "op", "USDT", "0x94b008aa00579c1307b0ef2c499ad98a8ce58e58"),
        _token("nep245:op-usdt0", "op", "USDT0", "0x01bff41798a0bcf287b996046ca68b395dbc1071"),
      ];

      expect(
        provider.currencyToNearAssetId(CryptoCurrency.usdtOp, tokens)?.assetId,
        "nep245:op-usdt0",
      );
    });

    test("does not map native NEAR to bridged NEAR on BSC", () {
      final tokens = [
        _token("nep245:bsc-near", "bsc", "NEAR", "0x1fa4a73a3f0133f0025378af00236f3abdee5d63"),
      ];

      expect(provider.currencyToNearAssetId(CryptoCurrency.near, tokens), isNull);
    });
  });
}
