import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";
import "package:cw_bitcoin/lightning/lightning_wallet.dart";
import "package:cw_bitcoin/lightning/conversion_status.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_bitcoin/lightning/spark_token.dart";
import "package:flutter_test/flutter_test.dart";

final _usdb = SparkToken(
  name: "USDB",
  symbol: "USDB",
  tokenIdentifier: "btkn1usdb",
  decimal: 6,
  enabled: true,
);

ConversionEstimate _estimate(ConversionType type, {AmountAdjustmentReason? adjustment}) =>
    ConversionEstimate(
      options: ConversionOptions(conversionType: type, maxSlippageBps: 100),
      amountIn: BigInt.from(4273100),
      amountOut: BigInt.from(5000),
      fee: BigInt.from(10200),
      amountAdjustment: adjustment,
    );

SparkToken? _resolve(String id) => id == _usdb.tokenIdentifier ? _usdb : null;

void main() {
  group("LightningWallet.sendConversionFrom", () {
    test("maps a stablecoin -> sats estimate into token spent and sats produced", () {
      final conversion = LightningWallet.sendConversionFrom(
        _estimate(
          const ConversionType.toBitcoin(fromTokenIdentifier: "btkn1usdb"),
          adjustment: AmountAdjustmentReason.flooredToMinLimit,
        ),
        resolveToken: _resolve,
      );

      expect(conversion, isNotNull);
      expect(conversion!.amountIn.amount, BigInt.from(4273100));
      expect(conversion.amountIn.currency, _usdb);
      expect(conversion.amountOut.amount, BigInt.from(5000));
      expect(conversion.amountOut.currency, CryptoCurrency.btcln);
      expect(conversion.fee.amount, BigInt.from(10200));
      expect(conversion.fee.currency, _usdb);
      expect(conversion.amountAdjustment, ConversionAmountAdjustment.flooredToMinLimit);
    });

    test("ignores a sats -> token estimate, which a Lightning send never funds from", () {
      final conversion = LightningWallet.sendConversionFrom(
        _estimate(const ConversionType.fromBitcoin()),
        resolveToken: _resolve,
      );

      expect(conversion, isNull);
    });

    test("is null when the SDK added no conversion", () {
      expect(LightningWallet.sendConversionFrom(null, resolveToken: _resolve), isNull);
    });

    test("is null for a token the wallet doesn't know", () {
      final conversion = LightningWallet.sendConversionFrom(
        _estimate(const ConversionType.toBitcoin(fromTokenIdentifier: "btkn1other")),
        resolveToken: _resolve,
      );

      expect(conversion, isNull);
    });
  });
}
