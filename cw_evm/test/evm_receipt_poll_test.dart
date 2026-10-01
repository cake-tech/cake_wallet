import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_evm/evm_chain_transaction_history.dart";
import "package:cw_evm/evm_chain_transaction_info.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("pendingTransactionOutcome", () {
    test("no receipt with the mined count above the nonce removes the row", () {
      expect(
        pendingTransactionOutcome(
          hasReceipt: false,
          isReverted: false,
          isKnownToNode: false,
          nonce: 5,
          transactionCount: 6,
        ),
        PendingTransactionOutcome.remove,
      );
    });

    test("a row the node still knows stays pending while its receipt lags the mined count", () {
      expect(
        pendingTransactionOutcome(
          hasReceipt: false,
          isReverted: false,
          isKnownToNode: true,
          nonce: 5,
          transactionCount: 6,
        ),
        PendingTransactionOutcome.keep,
      );
    });

    test("a receipt confirms the row the node also knows", () {
      expect(
        pendingTransactionOutcome(
          hasReceipt: true,
          isReverted: false,
          isKnownToNode: true,
          nonce: 5,
          transactionCount: 6,
        ),
        PendingTransactionOutcome.confirm,
      );
    });

    test("a receipt confirms the row", () {
      expect(
        pendingTransactionOutcome(
          hasReceipt: true,
          isReverted: false,
          isKnownToNode: false,
          nonce: 5,
          transactionCount: 6,
        ),
        PendingTransactionOutcome.confirm,
      );
    });

    test("a reverted receipt removes the row, as the history providers drop isError rows", () {
      expect(
        pendingTransactionOutcome(
          hasReceipt: true,
          isReverted: true,
          isKnownToNode: false,
          nonce: 5,
          transactionCount: 6,
        ),
        PendingTransactionOutcome.remove,
      );
    });

    test("no receipt and the nonce not yet used keeps the row pending", () {
      expect(
        pendingTransactionOutcome(
          hasReceipt: false,
          isReverted: false,
          isKnownToNode: false,
          nonce: 5,
          transactionCount: 5,
        ),
        PendingTransactionOutcome.keep,
      );
    });

    test("a row without a nonce stays pending until a receipt", () {
      expect(
        pendingTransactionOutcome(
          hasReceipt: false,
          isReverted: false,
          isKnownToNode: false,
          nonce: null,
          transactionCount: 9,
        ),
        PendingTransactionOutcome.keep,
      );
    });

    test("confirming keeps the row's id and clears pending", () {
      final pendingRow = EVMChainTransactionInfo(
        id: "0x5c504ed432cb51138bcf09aa5e8a410dd4a1e204ef84bfed1be16dfba1b22060",
        height: 0,
        amount: Money(BigInt.from(1000), CryptoCurrency.eth),
        fee: Money(BigInt.from(21000), CryptoCurrency.eth),
        tokenSymbol: "ETH",
        direction: TransactionDirection.outgoing,
        isPending: true,
        date: DateTime(2026, 9, 25),
        confirmations: 0,
        to: "0x8617E340B3D01FA5F11F306F4090FD50E238070D",
        from: "0x52908400098527886E0F7030069857D2E4169EE7",
        chainId: 10,
        nonce: 5,
      );

      final confirmed = pendingRow.confirmed(height: 123456);

      expect(confirmed.id, pendingRow.id);
      expect(confirmed.isPending, isFalse);
      expect(confirmed.height, 123456);
      expect(confirmed.nonce, 5);
      expect(confirmed.chainId, 10);
    });
  });
}
