import "package:bitcoin_base/bitcoin_base.dart";
import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";
import "package:cw_bitcoin/electrum.dart";
import "package:cw_bitcoin/electrum_wallet_exceptions.dart";
import "package:cw_bitcoin/lightning/unilateral_exit.dart";
import "package:flutter_test/flutter_test.dart";

/// Answers which txids the server knows and records what gets broadcast.
class FakeElectrumClient extends ElectrumClient {
  FakeElectrumClient({this.known = const {}, this.rejectBroadcasts = false});

  final Set<String> known;
  final bool rejectBroadcasts;
  final List<List<String>> broadcasts = [];

  @override
  Future<Map<String, dynamic>> getTransactionVerbose({required String hash}) async =>
      known.contains(hash) ? {"hex": ""} : {};

  @override
  Future<String> broadcastTransaction({
    required String transactionRaw,
    Object? network,
    Function(int)? idCallback,
  }) async {
    if (rejectBroadcasts) {
      return "";
    }

    broadcasts.add([transactionRaw]);
    return "txid";
  }

  @override
  Future<void> broadcastPackage({required List<String> rawTransactions}) async {
    if (rejectBroadcasts) {
      throw const PackageBroadcastException("min relay fee not met");
    }

    broadcasts.add(rawTransactions);
  }
}

/// A real CPFP child (a funding input, then a P2A anchor input with an empty witness), so
/// the plan can compute its txid.
final cpfpTxHex = [
  "03000000", "0001", "02",
  "22" * 32, "00000000", "00", "ffffffff",
  "11" * 32, "00000000", "00", "ffffffff",
  "01", "1027000000000000", "16", "0014${"33" * 20}",
  "02", "47", "44" * 71, "21", "02${"55" * 32}",
  "00", "00000000",
].join();

RecoveryTransaction tx(
  String txid, {
  RecoveryTxKind kind = RecoveryTxKind.node,
  String? nodeId,
  bool hasCpfp = false,
  int? csvTimelockBlocks,
  ExitTransactionStatus status = const ExitTransactionStatus.ready(),
}) =>
    RecoveryTransaction(
      kind: kind,
      nodeId: nodeId,
      txid: txid,
      txHex: "$txid-hex",
      cpfpTxHex: hasCpfp ? cpfpTxHex : null,
      csvTimelockBlocks: csvTimelockBlocks,
      dependsOn: const [],
      status: status,
    );

RecoverFundsResponse recovery(
  List<RecoveryTransaction> transactions, {
  List<RecoverFundsLeaf> leaves = const [],
  int refundFeeSats = 0,
  int sweepFeeSats = 0,
}) =>
    RecoverFundsResponse(
      recoverableValueSats: leaves.fold(BigInt.zero, (sum, leaf) => sum + leaf.valueSats),
      totalFeeSats: BigInt.from(1000),
      cooperativeFeeSats: BigInt.zero,
      cpfpFeeSats: BigInt.from(700),
      fanoutFeeSats: BigInt.zero,
      refundFeeSats: BigInt.from(refundFeeSats),
      sweepFeeSats: BigInt.from(sweepFeeSats),
      leaves: leaves,
      failed: const [],
      transactions: transactions,
      fundingInputs: [
        CpfpInput.p2Wpkh(
          txid: "funding",
          vout: 1,
          valueSats: BigInt.from(10120),
          pubkey: "02${"aa" * 32}",
        ),
      ],
      feeRateSatPerVbyte: BigInt.from(2),
      destination: "bc1qdestination",
    );

UnilateralExitPlan plan(
  RecoverFundsResponse recovery, {
  UnilateralExitStatus status = UnilateralExitStatus.active,
  Set<String> inMempoolTxids = const {},
}) =>
    UnilateralExitPlan(
      id: "1700000000000",
      recovery: recovery,
      startedAtMs: 1700000000000,
      accountIndex: 0,
      status: status,
      inMempoolTxids: inMempoolTxids,
    );

RecoverFundsLeaf leaf(String id, int valueSats, {bool cooperative = false}) => RecoverFundsLeaf(
      leafId: id,
      valueSats: BigInt.from(valueSats),
      method: cooperative ? RecoveryMethod.cooperative : RecoveryMethod.unilateral,
    );

void main() {
  group("UnilateralExitPlan storage", () {
    test("survives a JSON round trip, recovery included", () {
      final original = plan(
        recovery(
          [
            tx("node", hasCpfp: true, status: const ExitTransactionStatus.confirmed(blockHeight: 9)),
            tx(
              "refund",
              kind: RecoveryTxKind.refund,
              csvTimelockBlocks: 144,
              status: const ExitTransactionStatus.waitingForTimelock(spendableAtHeight: 975600),
            ),
            tx("coop", kind: RecoveryTxKind.cooperative, nodeId: "leaf-b"),
            tx("sweep", kind: RecoveryTxKind.sweep, status: const ExitTransactionStatus.unverified()),
          ],
          leaves: [leaf("leaf-a", 8192), leaf("leaf-b", 4096, cooperative: true)],
        ),
        status: UnilateralExitStatus.stalled,
        inMempoolTxids: {"node"},
      );

      final restored = UnilateralExitPlan.fromJson(original.toJson());

      expect(restored.toJson(), original.toJson());
      expect(restored.leafIds, ["leaf-a", "leaf-b"]);
      expect(restored.status, UnilateralExitStatus.stalled);
    });

    test("names the funding coins and the transactions that pay back to them", () {
      final exit = plan(
        recovery([
          tx("fanout", kind: RecoveryTxKind.fanOut),
          tx("node", hasCpfp: true),
          tx("sweep", kind: RecoveryTxKind.sweep),
        ]),
      );

      expect(exit.fundingOutpoints, {"funding:1"});
      expect(exit.fundingTxids, {"fanout", BtcTransaction.fromRaw(cpfpTxHex).txId()});
    });

    test("only a completed exit has stopped holding funds", () {
      final steps = recovery([tx("node")]);

      expect(plan(steps).isOngoing, isTrue);
      expect(plan(steps, status: UnilateralExitStatus.rebuild).isOngoing, isTrue);
      expect(plan(steps, status: UnilateralExitStatus.complete).isOngoing, isFalse);
    });
  });

  group("UnilateralExitPlan history", () {
    test("has a row per step and per fee payment, numbered in order", () {
      final entries = plan(
        recovery([
          tx("node", hasCpfp: true),
          tx("refund", kind: RecoveryTxKind.refund),
          tx("sweep", kind: RecoveryTxKind.sweep),
        ]),
      ).historyEntries;

      expect(entries.map((entry) => entry.kind), [
        UnilateralExitHistoryKind.node,
        UnilateralExitHistoryKind.fee,
        UnilateralExitHistoryKind.refund,
        UnilateralExitHistoryKind.sweep,
      ]);
      expect(entries.map((entry) => entry.stepNumber), [1, 1, 2, 3]);
      expect(entries.first.stepCount, 3);
    });

    test("reads each step's state from the SDK's status and the mempool", () {
      final entries = plan(
        recovery([
          tx("confirmed", status: const ExitTransactionStatus.confirmed()),
          tx("in-mempool"),
          tx("ready"),
          tx("dependencies", status: const ExitTransactionStatus.waitingForDependencies()),
          tx(
            "timelock",
            status: const ExitTransactionStatus.waitingForTimelock(spendableAtHeight: 975600),
          ),
          tx("unverified", status: const ExitTransactionStatus.unverified()),
        ]),
        inMempoolTxids: {"in-mempool"},
      ).historyEntries;

      expect(entries.map((entry) => entry.state), [
        UnilateralExitStepState.confirmed,
        UnilateralExitStepState.pending,
        UnilateralExitStepState.waiting,
        UnilateralExitStepState.waiting,
        UnilateralExitStepState.waitingForBlock,
        UnilateralExitStepState.checking,
      ]);
      expect(entries[4].additionalInfo["sparkExitSpendableAtHeight"], 975600);
    });

    test("a stalled exit marks the ready steps not on the network", () {
      final entries = plan(
        recovery([tx("in-mempool"), tx("rejected")]),
        status: UnilateralExitStatus.stalled,
        inMempoolTxids: {"in-mempool"},
      ).historyEntries;

      expect(entries.map((entry) => entry.state), [
        UnilateralExitStepState.pending,
        UnilateralExitStepState.stalled,
      ]);
    });

    test("an exit to rebuild marks every step that has not confirmed", () {
      final entries = plan(
        recovery([tx("done", status: const ExitTransactionStatus.confirmed()), tx("left")]),
        status: UnilateralExitStatus.rebuild,
      ).historyEntries;

      expect(entries.map((entry) => entry.state), [
        UnilateralExitStepState.confirmed,
        UnilateralExitStepState.rebuild,
      ]);
    });

    test("the sweep carries what the unilateral leaves deliver, net of their fees", () {
      final exit = plan(
        recovery(
          [
            tx("node"),
            tx("coop", kind: RecoveryTxKind.cooperative, nodeId: "leaf-b"),
            tx("sweep", kind: RecoveryTxKind.sweep),
          ],
          leaves: [leaf("leaf-a", 8192), leaf("leaf-b", 4096, cooperative: true)],
          refundFeeSats: 100,
          sweepFeeSats: 300,
        ),
      );

      expect(exit.historyEntries.map((entry) => entry.amountSat), [0, 4096, 7792]);
    });
  });

  group("UnilateralExitBroadcaster", () {
    test("sends only the steps the SDK reports ready", () async {
      final client = FakeElectrumClient();

      final progress = await UnilateralExitBroadcaster(electrumClient: client).broadcastReady(
        plan(
          recovery([
            tx("ready"),
            tx("waiting", status: const ExitTransactionStatus.waitingForDependencies()),
            tx("unverified", status: const ExitTransactionStatus.unverified()),
          ]),
        ),
      );

      expect(client.broadcasts, [
        ["ready-hex"],
      ]);
      expect(progress.inMempoolTxids, {"ready"});
      expect(progress.isStalled, isFalse);
    });

    test("sends a step with its CPFP child as a package", () async {
      final client = FakeElectrumClient();

      await UnilateralExitBroadcaster(electrumClient: client).broadcastReady(
        plan(recovery([tx("node", hasCpfp: true)])),
      );

      expect(client.broadcasts, [
        ["node-hex", cpfpTxHex],
      ]);
    });

    test("leaves alone a ready step the server already has", () async {
      final client = FakeElectrumClient(known: {"node"});

      final progress = await UnilateralExitBroadcaster(electrumClient: client).broadcastReady(
        plan(recovery([tx("node")])),
      );

      expect(client.broadcasts, isEmpty);
      expect(progress.inMempoolTxids, {"node"});
    });

    test("a rejected ready step stalls the exit without throwing", () async {
      final client = FakeElectrumClient(rejectBroadcasts: true);

      final progress = await UnilateralExitBroadcaster(electrumClient: client).broadcastReady(
        plan(recovery([tx("node", hasCpfp: true)])),
      );

      expect(progress.isStalled, isTrue);
      expect(progress.broadcastError, isNotNull);
      expect(progress.inMempoolTxids, isEmpty);
    });
  });
}
