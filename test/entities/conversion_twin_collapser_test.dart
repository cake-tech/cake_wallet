import "package:cw_core/amount/money.dart";
import "package:cake_wallet/entities/conversion_twin_collapser.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_info.dart";
import "package:flutter_test/flutter_test.dart";

class _FakeTransactionInfo extends TransactionInfo {
  _FakeTransactionInfo(
    String txId, {
    required TransactionDirection txDirection,
    Map<String, dynamic> info = const {},
  }) {
    id = txId;
    amount = Money.zero(CryptoCurrency.btcln);
    direction = txDirection;
    isPending = false;
    date = DateTime(2026);
    additionalInfo = info;
  }
}

void main() {
  group("ConversionTwinCollapser.transactionIdsToDrop", () {
    test("drops the outgoing half of a tagged pair sharing a payment hash", () {
      final outgoing = _FakeTransactionInfo(
        "out",
        txDirection: TransactionDirection.outgoing,
        info: {"paymentHash": "hash1"},
      );
      final incoming = _FakeTransactionInfo(
        "in",
        txDirection: TransactionDirection.incoming,
        info: {"paymentHash": "hash1", "conversionToTicker": "USDB"},
      );

      final dropped = ConversionTwinCollapser.transactionIdsToDrop([outgoing, incoming]);

      expect(dropped, {"out"});
    });

    test("pairs Stable Balance conversion legs by conversionId when they have no payment hash", () {
      final tokenSend = _FakeTransactionInfo(
        "token-send",
        txDirection: TransactionDirection.outgoing,
        info: {"conversionId": "c1", "conversionToTicker": "BTC"},
      );
      final satsReceive = _FakeTransactionInfo(
        "sats-receive",
        txDirection: TransactionDirection.incoming,
        info: {"conversionId": "c1", "conversionToTicker": "BTC"},
      );

      final dropped = ConversionTwinCollapser.transactionIdsToDrop([tokenSend, satsReceive]);

      expect(dropped, {"token-send"});
    });

    test("prefers the leg carrying the SDK's full conversion details over asset tags alone", () {
      final outgoing = _FakeTransactionInfo(
        "out",
        txDirection: TransactionDirection.outgoing,
        info: {"conversionId": "c2", "conversionToTicker": "BTC", "conversionFromAmount": "5"},
      );
      final incoming = _FakeTransactionInfo(
        "in",
        txDirection: TransactionDirection.incoming,
        info: {"conversionId": "c2", "conversionToTicker": "BTC"},
      );

      final dropped = ConversionTwinCollapser.transactionIdsToDrop([outgoing, incoming]);

      expect(dropped, {"in"});
    });

    test("keeps the outgoing half when only it carries the conversion tag", () {
      final outgoing = _FakeTransactionInfo(
        "out",
        txDirection: TransactionDirection.outgoing,
        info: {"paymentHash": "hash1", "conversionToTicker": "USDB"},
      );
      final incoming = _FakeTransactionInfo(
        "in",
        txDirection: TransactionDirection.incoming,
        info: {"paymentHash": "hash1"},
      );

      final dropped = ConversionTwinCollapser.transactionIdsToDrop([outgoing, incoming]);

      expect(dropped, {"in"});
    });

    test("falls back to preimage as the pairing key for older untagged records", () {
      final outgoing = _FakeTransactionInfo(
        "out",
        txDirection: TransactionDirection.outgoing,
        info: {"preimage": "abc"},
      );
      final incoming = _FakeTransactionInfo(
        "in",
        txDirection: TransactionDirection.incoming,
        info: {"preimage": "abc"},
      );

      final dropped = ConversionTwinCollapser.transactionIdsToDrop([outgoing, incoming]);

      expect(dropped, {"out"});
    });

    test("a lone external Lightning send with no matching pair stays visible", () {
      final lone = _FakeTransactionInfo(
        "lone",
        txDirection: TransactionDirection.outgoing,
        info: {"paymentHash": "unique"},
      );

      expect(ConversionTwinCollapser.transactionIdsToDrop([lone]), isEmpty);
    });

    test("a same-direction pair sharing a key is not collapsed", () {
      final a = _FakeTransactionInfo(
        "a",
        txDirection: TransactionDirection.outgoing,
        info: {"paymentHash": "hash1"},
      );
      final b = _FakeTransactionInfo(
        "b",
        txDirection: TransactionDirection.outgoing,
        info: {"paymentHash": "hash1"},
      );

      expect(ConversionTwinCollapser.transactionIdsToDrop([a, b]), isEmpty);
    });

    test("more than two transactions sharing a key are left untouched", () {
      final a = _FakeTransactionInfo("a",
          txDirection: TransactionDirection.outgoing, info: {"paymentHash": "hash1"});
      final b = _FakeTransactionInfo("b",
          txDirection: TransactionDirection.incoming, info: {"paymentHash": "hash1"});
      final c = _FakeTransactionInfo("c",
          txDirection: TransactionDirection.incoming, info: {"paymentHash": "hash1"});

      expect(ConversionTwinCollapser.transactionIdsToDrop([a, b, c]), isEmpty);
    });

    test("non-Lightning transactions with neither key are untouched", () {
      final tx = _FakeTransactionInfo("plain", txDirection: TransactionDirection.incoming);

      expect(ConversionTwinCollapser.transactionIdsToDrop([tx]), isEmpty);
    });
  });
}
