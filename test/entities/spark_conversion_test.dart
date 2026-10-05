import "package:cake_wallet/entities/spark_conversion.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

// A plain 6-decimal currency stands in for the Spark token - these only care about decimals/symbol.
const _usdb = CryptoCurrency(
  title: "USDB",
  name: "usdb",
  fullName: "USDB",
  decimals: 6,
  tag: "BTC",
  enabled: true,
);

StableBalanceSendConversion _conversion(
        {required int amountIn, required int fee, int sats = 5000}) =>
    StableBalanceSendConversion(
      amountIn: Money(BigInt.from(amountIn), _usdb),
      amountOut: Money(BigInt.from(sats), CryptoCurrency.btcln),
      fee: Money(BigInt.from(fee), _usdb),
    );

void main() {
  group("StableBalanceSendConversion.satsPerWholeToken", () {
    test("is the pool rate: sats out per whole token actually swapped, fee excluded", () {
      // 4.2731 USDB in, 0.0102 of it the fee, so 4.2629 USDB bought 5000 sats.
      final conversion = _conversion(amountIn: 4273100, fee: 10200);

      expect(conversion.satsPerWholeToken, BigInt.from(1172));
    });

    test("is null when the fee swallows the whole input", () {
      expect(_conversion(amountIn: 100, fee: 100).satsPerWholeToken, isNull);
    });
  });
}
