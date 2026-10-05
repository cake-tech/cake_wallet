import "package:cake_wallet/new-ui/viewmodels/spark_deposit_to_stable/spark_deposit_to_stable_bloc.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter_test/flutter_test.dart";

/// Full Breez SDK FFI interactions (`prepareBitcoinToStableConversion`,
/// `fetchStableConversionLimits`) can't be unit-tested without deep mocking of the SDK's native
/// bindings, the same established gap documented by
/// `cw_bitcoin/test/lightning_wallet_uninitialized_test.dart` and
/// `cw_bitcoin/test/stable_balance_config_test.dart`. This file only covers the pure,
/// no-SDK-call logic [SparkDepositToStableBloc] factors out for exactly that reason:
/// [SparkDepositToStableBloc.satsTextToMoney], [SparkDepositToStableBloc.fiatTextToSats],
/// [SparkDepositToStableBloc.satsToFiatText] and [SparkDepositToStableBloc.isBelowMinimum].
void main() {
  group("SparkDepositToStableBloc.satsTextToMoney", () {
    test("parses a whole number of sats", () {
      final amount = SparkDepositToStableBloc.satsTextToMoney("1000");

      expect(amount, isNotNull);
      expect(amount!.currency, CryptoCurrency.btcln);
      expect(amount.amount, BigInt.from(1000));
    });

    test("returns null for blank input", () {
      expect(SparkDepositToStableBloc.satsTextToMoney(""), isNull);
      expect(SparkDepositToStableBloc.satsTextToMoney("   "), isNull);
    });

    test("returns null for unparsable input", () {
      expect(SparkDepositToStableBloc.satsTextToMoney("not a number"), isNull);
    });
  });

  group("SparkDepositToStableBloc.fiatTextToSats", () {
    // 1 BTC = 100,000,000 sats = \$50,000 at this price, so \$50 -> 100,000 sats.
    const btcPrice = 50000.0;

    test("converts a fiat amount to sats using the given BTC price", () {
      final amount = SparkDepositToStableBloc.fiatTextToSats("50", btcPrice);

      expect(amount, isNotNull);
      expect(amount!.currency, CryptoCurrency.btcln);
      expect(amount.amount, BigInt.from(100000));
    });

    test("returns null when there's no BTC price yet", () {
      expect(SparkDepositToStableBloc.fiatTextToSats("50", null), isNull);
    });

    test("returns null for a non-positive or non-finite price", () {
      expect(SparkDepositToStableBloc.fiatTextToSats("50", 0), isNull);
      expect(SparkDepositToStableBloc.fiatTextToSats("50", -1), isNull);
      expect(SparkDepositToStableBloc.fiatTextToSats("50", double.nan), isNull);
    });

    test("returns null for blank or unparsable input", () {
      expect(SparkDepositToStableBloc.fiatTextToSats("", btcPrice), isNull);
      expect(SparkDepositToStableBloc.fiatTextToSats("not a number", btcPrice), isNull);
    });
  });

  group("SparkDepositToStableBloc.satsToFiatText", () {
    const btcPrice = 50000.0;

    test("converts sats to a fiat display string using the given BTC price", () {
      expect(SparkDepositToStableBloc.satsToFiatText(BigInt.from(100000), btcPrice), "50.00");
    });

    test("is the inverse of fiatTextToSats for a round-trippable amount", () {
      final sats = SparkDepositToStableBloc.fiatTextToSats("50", btcPrice)!;

      expect(SparkDepositToStableBloc.satsToFiatText(sats.amount, btcPrice), "50.00");
    });

    test("returns an empty string when there's no BTC price yet", () {
      expect(SparkDepositToStableBloc.satsToFiatText(BigInt.from(100000), null), "");
    });

    test("returns an empty string for a non-positive price", () {
      expect(SparkDepositToStableBloc.satsToFiatText(BigInt.from(100000), 0), "");
    });
  });

  group("SparkDepositToStableBloc.isBelowMinimum", () {
    const token = CryptoCurrency.usdt;

    test("is false when there's no minimum to compare against", () {
      final amount = Money.fromInt(1, token);

      expect(SparkDepositToStableBloc.isBelowMinimum(amount, null), isFalse);
    });

    test("is true when the amount is strictly below the minimum", () {
      final amount = Money.fromInt(1, token);
      final min = Money.fromInt(10, token);

      expect(SparkDepositToStableBloc.isBelowMinimum(amount, min), isTrue);
    });

    test("is false when the amount equals the minimum", () {
      final amount = Money.fromInt(10, token);
      final min = Money.fromInt(10, token);

      expect(SparkDepositToStableBloc.isBelowMinimum(amount, min), isFalse);
    });

    test("is false when the amount is above the minimum", () {
      final amount = Money.fromInt(100, token);
      final min = Money.fromInt(10, token);

      expect(SparkDepositToStableBloc.isBelowMinimum(amount, min), isFalse);
    });

    test("compares sats amounts (the primary input denomination) correctly", () {
      final amount = SparkDepositToStableBloc.satsTextToMoney("500")!;
      final min = SparkDepositToStableBloc.satsTextToMoney("1000")!;

      expect(SparkDepositToStableBloc.isBelowMinimum(amount, min), isTrue);
    });
  });
}
