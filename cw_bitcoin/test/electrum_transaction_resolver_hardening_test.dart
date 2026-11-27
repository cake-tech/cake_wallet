import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_bitcoin/electrum_transaction_resolver.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/raw_transaction.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

import "raw_tx_hex.dart";

/// Only the cache and the merge helper are exercised, so the wallet is an unstubbed fake.
class _Unstubbed {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("${invocation.memberName} is not stubbed in this fake");
}

class _FakeWallet extends _Unstubbed implements ElectrumWalletBase {}

void main() {
  final outScript = "0014${"33" * 20}";

  /// A transaction whose only input spends the txid made from [n], so each [n]
  /// gives a distinct txid with the same serialized length.
  String hexSpending(int n, {String scriptSig = ""}) => rawTxHex(
        inputs: [
          RawInput(
            txid: n.toRadixString(16).padLeft(2, "0") * 32,
            scriptSig: scriptSig,
          ),
        ],
        outputs: [RawOutput(amount: 50000, scriptPubKey: outScript)],
      );

  group("raw tx hex cache cap", () {
    final hexes = [for (var n = 1; n <= 5; n++) hexSpending(n)];
    final txids = [for (final hex in hexes) parseRawTransaction(hex)!.txId];
    final hexLength = hexes.first.length;

    test("the hexes used here are all the same length", () {
      expect(hexes.map((hex) => hex.length).toSet(), hasLength(1));
    });

    test("evicts the oldest entries and keeps the newest", () {
      final resolver = ElectrumTransactionResolver(
        _FakeWallet(),
        rawTxHexCacheCapChars: hexLength * 3,
      );

      for (var i = 0; i < hexes.length; i++) {
        resolver.cacheRawTxHex(txids[i], hexes[i]);
      }

      expect(resolver.cachedRawTxHex(txids[0]), isNull);
      expect(resolver.cachedRawTxHex(txids[1]), isNull);
      expect(resolver.cachedRawTxHex(txids[2]), hexes[2]);
      expect(resolver.cachedRawTxHex(txids[3]), hexes[3]);
      expect(resolver.cachedRawTxHex(txids[4]), hexes[4]);
    });

    test("a hex larger than the whole cap is not kept and evicts nothing", () {
      final big = hexSpending(9, scriptSig: "ab" * 300);
      final bigTxid = parseRawTransaction(big)!.txId;
      final resolver = ElectrumTransactionResolver(
        _FakeWallet(),
        rawTxHexCacheCapChars: hexLength * 2,
      );
      expect(big.length, greaterThan(hexLength * 2));

      resolver.cacheRawTxHex(txids[0], hexes[0]);
      resolver.cacheRawTxHex(txids[1], hexes[1]);
      resolver.cacheRawTxHex(bigTxid, big);

      expect(resolver.cachedRawTxHex(bigTxid), isNull);
      expect(resolver.cachedRawTxHex(txids[0]), hexes[0]);
      expect(resolver.cachedRawTxHex(txids[1]), hexes[1]);
    });

    test("re-caching the same txid does not count its hex twice", () {
      final resolver = ElectrumTransactionResolver(
        _FakeWallet(),
        rawTxHexCacheCapChars: hexLength * 2,
      );

      resolver.cacheRawTxHex(txids[0], hexes[0]);
      resolver.cacheRawTxHex(txids[0], hexes[0]);
      resolver.cacheRawTxHex(txids[1], hexes[1]);

      // Two entries fit exactly, so a double-counted first entry would have evicted it.
      expect(resolver.cachedRawTxHex(txids[0]), hexes[0]);
      expect(resolver.cachedRawTxHex(txids[1]), hexes[1]);
    });

    test("a hex filed under the wrong txid is not cached and uses no room", () {
      final resolver = ElectrumTransactionResolver(
        _FakeWallet(),
        rawTxHexCacheCapChars: hexLength * 2,
      );

      resolver.cacheRawTxHex(txids[0], hexes[1]);
      resolver.cacheRawTxHex(txids[1], hexes[1]);
      resolver.cacheRawTxHex(txids[2], hexes[2]);

      // Two correctly filed entries fit exactly, so the rejected one must not have taken room.
      expect(resolver.cachedRawTxHex(txids[0]), isNull);
      expect(resolver.cachedRawTxHex(txids[1]), hexes[1]);
      expect(resolver.cachedRawTxHex(txids[2]), hexes[2]);
    });
  });

  group("ElectrumTransactionResolver.mergeResolved", () {
    final currency = walletTypeToCryptoCurrency(WalletType.bitcoin);
    final base = DateTime(2024, 1, 1);

    ElectrumTransactionInfo record({
      required DateTime date,
      String id = "tx-id",
      bool isPending = false,
      Map<String, dynamic>? additionalInfo,
    }) =>
        ElectrumTransactionInfo(
          WalletType.bitcoin,
          id: id,
          amount: Money.fromInt(50000, currency),
          direction: TransactionDirection.incoming,
          isPending: isPending,
          date: date,
          confirmations: 0,
          additionalInfo: additionalInfo,
        );

    test("keeps what the chain cannot re-derive and merges additionalInfo", () {
      final existing = record(
        date: base,
        isPending: true,
        additionalInfo: {"note": "kept", "owned": true},
      )
        ..to = "bc1qto"
        ..from = "bc1qfrom"
        ..unspents = []
        ..isReceivedSilentPayment = true
        ..accountIndex = 3;
      final rebuilt = record(
        date: DateTime(2025, 6, 1),
        additionalInfo: {"fresh": 1, "note": "new"},
      );

      final merged = ElectrumTransactionResolver.mergeResolved(existing, rebuilt);

      expect(identical(merged, rebuilt), isTrue);
      expect(merged.date, base);
      expect(merged.isPending, isTrue);
      expect(merged.to, "bc1qto");
      expect(merged.from, "bc1qfrom");
      expect(identical(merged.unspents, existing.unspents), isTrue);
      expect(merged.isReceivedSilentPayment, isTrue);
      expect(merged.accountIndex, 3);
      // Rebuilt keys win on a clash; keys only the existing record has survive.
      expect(merged.additionalInfo, {"note": "new", "owned": true, "fresh": 1});
    });

    test("takes the rebuilt account index when it has one", () {
      final existing = record(date: base)..accountIndex = 3;
      final rebuilt = record(date: base)..accountIndex = 5;

      ElectrumTransactionResolver.mergeResolved(existing, rebuilt);

      expect(rebuilt.accountIndex, 5);
    });

    test("sets id from the existing record and isReplaced to false when it has none", () {
      final existing = record(date: base, id: "existing-id")..isReplaced = null;
      final rebuilt = record(date: base, id: "rebuilt-id")..isReplaced = true;

      ElectrumTransactionResolver.mergeResolved(existing, rebuilt);

      expect(rebuilt.id, "existing-id");
      expect(rebuilt.isReplaced, isFalse);
    });
  });
}
