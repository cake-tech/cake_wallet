import "package:cw_bitcoin/bitcoin_wallet.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("shouldRouteToLightning", () {
    test("a Spark token send always routes to Lightning", () {
      expect(
        SparkSendRouting.shouldRouteToLightning(
          coinTypeToSpendFrom: UnspentCoinType.any,
          hasLightningWallet: true,
          isLightningCompatibleAddress: false,
          isSparkToken: true,
        ),
        isTrue,
      );
    });

    test(
        "a Lightning-compatible destination routes to Lightning even without an explicit"
        " coin type", () {
      expect(
        SparkSendRouting.shouldRouteToLightning(
          coinTypeToSpendFrom: UnspentCoinType.any,
          hasLightningWallet: true,
          isLightningCompatibleAddress: true,
          isSparkToken: false,
        ),
        isTrue,
      );
    });

    test("an explicit lightning coin type routes to Lightning when a Lightning wallet exists", () {
      expect(
        SparkSendRouting.shouldRouteToLightning(
          coinTypeToSpendFrom: UnspentCoinType.lightning,
          hasLightningWallet: true,
          isLightningCompatibleAddress: false,
          isSparkToken: false,
        ),
        isTrue,
      );
    });

    test("an explicit lightning coin type without a Lightning wallet falls back on-chain", () {
      expect(
        SparkSendRouting.shouldRouteToLightning(
          coinTypeToSpendFrom: UnspentCoinType.lightning,
          hasLightningWallet: false,
          isLightningCompatibleAddress: false,
          isSparkToken: false,
        ),
        isFalse,
      );
    });

    test("a plain on-chain send with no Lightning signal stays on-chain", () {
      expect(
        SparkSendRouting.shouldRouteToLightning(
          coinTypeToSpendFrom: UnspentCoinType.any,
          hasLightningWallet: true,
          isLightningCompatibleAddress: false,
          isSparkToken: false,
        ),
        isFalse,
      );
    });
  });
}
