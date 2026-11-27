import "package:cw_bitcoin/electrum_transaction_resolver.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/raw_transaction.dart";
import "package:flutter_test/flutter_test.dart";

import "raw_tx_hex.dart";

/// Only the cache writer is exercised, so the wallet is an unstubbed fake.
class _Unstubbed {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("${invocation.memberName} is not stubbed in this fake");
}

class _FakeWallet extends _Unstubbed implements ElectrumWalletBase {}

void main() {
  late ElectrumTransactionResolver resolver;

  setUp(() => resolver = ElectrumTransactionResolver(_FakeWallet()));

  final outScript = "0014${"33" * 20}";
  final realHex = rawTxHex(
    inputs: [RawInput(txid: "aa" * 32)],
    outputs: [RawOutput(amount: 50000, scriptPubKey: outScript)],
  );
  final realTxid = parseRawTransaction(realHex)!.txId;

  final otherHex = rawTxHex(
    inputs: [RawInput(txid: "cc" * 32)],
    outputs: [RawOutput(amount: 1, scriptPubKey: outScript)],
  );

  group("cacheRawTxHex keeps only hex that is really the transaction", () {
    test("hex matching its txid is cached", () {
      resolver.cacheRawTxHex(realTxid, realHex);

      expect(resolver.cachedRawTxHex(realTxid), realHex);
    });

    test("hex filed under a different txid is not cached", () {
      // A node that answers with the wrong transaction must not poison the
      // cache, which outlives a node switch.
      resolver.cacheRawTxHex(realTxid, otherHex);

      expect(resolver.cachedRawTxHex(realTxid), isNull);
    });

    test("an MWEB-flagged hex is not cached, since it can't be checked against its txid", () {
      final mwebHex = rawTxHex(
        inputs: [RawInput(txid: "aa" * 32)],
        outputs: [RawOutput(amount: 50000, scriptPubKey: outScript)],
        witnesses: [
          ["11", "02${"ab" * 32}"],
        ],
        mweb: "abcdef0123",
      );

      resolver.cacheRawTxHex("0" * 64, mwebHex);

      expect(resolver.cachedRawTxHex("0" * 64), isNull);
    });

    test("an empty hex is not cached", () {
      resolver.cacheRawTxHex(realTxid, "");

      expect(resolver.cachedRawTxHex(realTxid), isNull);
    });
  });
}
