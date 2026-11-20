import "package:cw_bitcoin/bitcoin_unspent.dart";
import "package:cw_core/unspent_transaction_output.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("matchesUnspentOutpoint", () {
    final unspent = Unspent("address", "transaction-a", 1000, 1, null);

    test("matches the same transaction hash and output index", () {
      expect(
        matchesUnspentOutpoint(unspent, transactionHash: "transaction-a", outputIndex: 1),
        isTrue,
      );
    });

    test("does not match a sibling output from the same transaction", () {
      expect(
        matchesUnspentOutpoint(unspent, transactionHash: "transaction-a", outputIndex: 0),
        isFalse,
      );
    });

    test("does not match the same output index from another transaction", () {
      expect(
        matchesUnspentOutpoint(unspent, transactionHash: "transaction-b", outputIndex: 1),
        isFalse,
      );
    });
  });
}
