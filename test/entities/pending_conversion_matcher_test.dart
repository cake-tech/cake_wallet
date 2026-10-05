import "package:cake_wallet/entities/pending_conversion.dart";
import "package:cake_wallet/entities/pending_conversion_matcher.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_info.dart";
import "package:flutter_test/flutter_test.dart";

class _FakeTransactionInfo extends TransactionInfo {
  _FakeTransactionInfo(String txId, {Map<String, dynamic> info = const {}}) {
    id = txId;
    amount = Money.zero(CryptoCurrency.btcln);
    direction = TransactionDirection.incoming;
    isPending = false;
    date = DateTime(2026);
    additionalInfo = info;
  }
}

void main() {
  PendingConversion pendingConversion({String? paymentHash}) => PendingConversion(
        paymentId: "payment-1",
        paymentHash: paymentHash,
        walletId: "wallet-1",
        fromTicker: "BTC",
        toTicker: "USDB",
        toIsToken: true,
        amountOutBaseUnits: "1000000",
        amountOutDecimals: 6,
        createdAt: DateTime(2026),
      );

  group("PendingConversionMatcher.matches", () {
    test("matches by payment id when the real tx has reached a terminal status", () {
      final pending = pendingConversion();
      final tx = _FakeTransactionInfo("payment-1", info: {"conversionStatus": "completed"});

      expect(PendingConversionMatcher.matches(pending, tx), isTrue);
    });

    test("matches by payment hash when the id differs (self-transfer twin)", () {
      final pending = pendingConversion(paymentHash: "hash-1");
      final tx = _FakeTransactionInfo(
        "a-different-payment-id",
        info: {"paymentHash": "hash-1", "conversionStatus": "failed"},
      );

      expect(PendingConversionMatcher.matches(pending, tx), isTrue);
    });

    test("does not match a same-id tx that's still pending", () {
      final pending = pendingConversion();
      final tx = _FakeTransactionInfo("payment-1", info: {"conversionStatus": "pending"});

      expect(PendingConversionMatcher.matches(pending, tx), isFalse);
    });

    test("does not match when neither id nor hash line up", () {
      final pending = pendingConversion(paymentHash: "hash-1");
      final tx = _FakeTransactionInfo(
        "some-other-id",
        info: {"paymentHash": "some-other-hash", "conversionStatus": "completed"},
      );

      expect(PendingConversionMatcher.matches(pending, tx), isFalse);
    });

    test("does not match a same-id tx with no conversion status at all", () {
      final pending = pendingConversion();
      final tx = _FakeTransactionInfo("payment-1");

      expect(PendingConversionMatcher.matches(pending, tx), isFalse);
    });

    for (final status in ["refundNeeded", "refunded"]) {
      test("matches a same-id tx with terminal status '$status'", () {
        final pending = pendingConversion();
        final tx = _FakeTransactionInfo("payment-1", info: {"conversionStatus": status});

        expect(PendingConversionMatcher.matches(pending, tx), isTrue);
      });
    }
  });
}
