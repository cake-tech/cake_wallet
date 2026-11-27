import "package:cw_bitcoin/electrum_transaction_history.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_bitcoin/electrum_transaction_resolver.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mobx/mobx.dart";

/// Records the on-chain data can't classify must never be refetched by the
/// background recheck or by a refresh of the open transaction, since a refetch
/// would overwrite the amount and ownership they were stored with.
class _Unstubbed {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError("${invocation.memberName} is not stubbed in this fake");
}

class _FakeHistory extends _Unstubbed implements ElectrumTransactionHistory {
  _FakeHistory(Map<String, ElectrumTransactionInfo> initial) {
    transactions.addAll(initial);
  }

  @override
  ObservableMap<String, ElectrumTransactionInfo> transactions = ObservableMap();

  int addOneCalls = 0;
  int saveCalls = 0;

  @override
  void addOne(ElectrumTransactionInfo transaction) {
    addOneCalls++;
    transactions[transaction.id] = transaction;
  }

  @override
  Future<void> save() async {
    saveCalls++;
  }
}

class _Fetch {
  _Fetch(this.hashes, {required this.forceResolveInputs});

  final List<String> hashes;
  final bool forceResolveInputs;
}

class _FakeWallet extends _Unstubbed implements ElectrumWalletBase {
  _FakeWallet({
    required _FakeHistory history,
    required this.classificationAddressesSet,
  }) {
    transactionHistory = history;
  }

  @override
  late ElectrumTransactionHistory transactionHistory;

  @override
  final Set<String> classificationAddressesSet;

  @override
  final Map<int, Set<String>> classificationAddressesSetByAccount = const {};

  /// Every fetch the resolver asked for, in call order. The fake answers each
  /// with an empty map, so nothing is rewritten.
  final List<_Fetch> fetches = [];

  @override
  Future<Map<String, ElectrumTransactionInfo?>> fetchTransactionInfoBatch({
    required List<String> hashes,
    Map<String, int?>? heightsByHash,
    bool retryOnFailure = false,
    Duration retryDelay = const Duration(seconds: 2),
    bool forceResolveInputs = false,
  }) async {
    fetches.add(_Fetch(hashes, forceResolveInputs: forceResolveInputs));
    return <String, ElectrumTransactionInfo?>{};
  }
}

void main() {
  final currency = walletTypeToCryptoCurrency(WalletType.bitcoin);
  final date = DateTime(2024, 1, 1);
  final amount = Money.fromInt(50000, currency);
  const walletAddress = "bc1qwalletaddress";
  const newAddress = "bc1qnewaddress";
  const spOutputAddress = "bc1pspoutput";
  const mwebOutputId = "mwebOutputId";

  /// A stored record with no fee yet, which is what makes it "needs resolution"
  /// for the open-transaction path.
  ElectrumTransactionInfo record(
    String id, {
    List<String>? outputAddresses,
    bool isReceivedSilentPayment = false,
    Map<String, dynamic>? additionalInfo,
    Money? fee,
  }) =>
      ElectrumTransactionInfo(
        WalletType.bitcoin,
        id: id,
        amount: amount,
        fee: fee,
        direction: TransactionDirection.incoming,
        isPending: false,
        date: date,
        confirmations: 10,
        outputAddresses: outputAddresses ?? [walletAddress],
        isReceivedSilentPayment: isReceivedSilentPayment,
        inputsOwnershipFullyResolved: true,
        additionalInfo: additionalInfo,
      );

  final silentPayment = record(
    "sp",
    isReceivedSilentPayment: true,
    outputAddresses: [spOutputAddress],
  );
  final lightning = record("ln", additionalInfo: {"isLightning": true});
  final spark = record(
    "spark",
    additionalInfo: {"isLightning": true, "isSparkDeposit": true},
  );
  final mweb = record(mwebOutputId, outputAddresses: [mwebOutputId]);
  final gated = [silentPayment, lightning, spark, mweb];

  late ElectrumTransactionResolver resolver;

  tearDown(() => resolver.stop());

  group("recheckStaleTransactions", () {
    for (final tx in gated) {
      test("never fetches or rewrites a gated record (${tx.id}), even when flagged stale",
          () async {
        final history = _FakeHistory({tx.id: tx});
        final wallet = _FakeWallet(history: history, classificationAddressesSet: {walletAddress, newAddress});
        resolver = ElectrumTransactionResolver(wallet);

        final stale = tx.outputAddresses!.first;
        expect(
          ElectrumTransactionResolver.isStaleForAddress(tx, stale),
          isTrue,
          reason: "the record must be flagged, or the test proves nothing",
        );
        resolver.flagIfStale(tx, stale);

        await resolver.recheckStaleTransactions();

        expect(wallet.fetches, isEmpty);
        expect(history.addOneCalls, 0);
        expect(history.transactions[tx.id], same(tx));
        expect(history.transactions[tx.id]!.amount, amount);
      });
    }

    test("fetches an ordinary record that a newly discovered address made stale", () async {
      final ordinary = record(
        "ordinary",
        outputAddresses: [walletAddress, newAddress],
        fee: Money.zero(currency),
        additionalInfo: {"addressSetSizeKey": 1},
      );
      final history = _FakeHistory({ordinary.id: ordinary});
      final wallet = _FakeWallet(history: history, classificationAddressesSet: {walletAddress, newAddress});
      resolver = ElectrumTransactionResolver(wallet);

      resolver.flagIfStale(ordinary, newAddress);
      await resolver.recheckStaleTransactions();

      expect(wallet.fetches.map((f) => f.hashes).expand((h) => h), ["ordinary"]);
    });

    test("fetches a legacy ordinary record with a newly recognized output", () async {
      // No address set size recorded, so the recheck falls back to the
      // heuristic: an output the wallet now owns that the record doesn't list.
      final legacy = record(
        "legacy",
        outputAddresses: [walletAddress, newAddress],
        fee: Money.zero(currency),
        additionalInfo: {
          "ownedOutputs": [
            {"address": walletAddress},
          ],
          "ownedInputs": <Map<String, dynamic>>[],
        },
      );
      final history = _FakeHistory({legacy.id: legacy});
      final wallet = _FakeWallet(history: history, classificationAddressesSet: {walletAddress, newAddress});
      resolver = ElectrumTransactionResolver(wallet);

      await resolver.recheckStaleTransactions();

      expect(wallet.fetches.map((f) => f.hashes).expand((h) => h), ["legacy"]);
    });
  });

  group("refreshIfStale", () {
    for (final tx in gated) {
      test("returns a gated record (${tx.id}) unchanged without fetching or prioritizing it",
          () async {
        final history = _FakeHistory({tx.id: tx});
        final wallet = _FakeWallet(history: history, classificationAddressesSet: {walletAddress, newAddress});
        resolver = ElectrumTransactionResolver(wallet);

        expect(
          tx.needsResolution,
          isTrue,
          reason: "the record must look like it needs resolution, or the gate is not tested",
        );

        final result = await resolver.refreshIfStale(tx.id);

        expect(result, same(tx));
        expect(result!.amount, amount);
        expect(wallet.fetches, isEmpty);
        expect(resolver.resolutionProgress, isEmpty);
        expect(history.addOneCalls, 0);
      });
    }

    test("refetches an ordinary record whose address set grew, with forced input resolution",
        () async {
      final ordinary = record(
        "ordinary",
        fee: Money.zero(currency),
        additionalInfo: {"addressSetSizeKey": 1},
      );
      final history = _FakeHistory({ordinary.id: ordinary});
      final wallet = _FakeWallet(history: history, classificationAddressesSet: {walletAddress, newAddress});
      resolver = ElectrumTransactionResolver(wallet);

      await resolver.refreshIfStale(ordinary.id);

      expect(wallet.fetches, hasLength(1));
      expect(wallet.fetches.single.hashes, ["ordinary"]);
      expect(wallet.fetches.single.forceResolveInputs, isTrue);
    });
  });
}
