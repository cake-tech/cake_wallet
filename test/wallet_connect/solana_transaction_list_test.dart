import "dart:convert";

import "package:cake_wallet/src/screens/wallet_connect/services/chain_service/solana/solana_transaction_list.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("reads signAllTransactions payloads from decoded JSON", () {
    final params = jsonDecode('{"transactions":["aaaa","bbbb"]}') as Map<String, dynamic>;

    expect(readSolanaSignAllTransactions(params["transactions"]), ["aaaa", "bbbb"]);
  });
}
