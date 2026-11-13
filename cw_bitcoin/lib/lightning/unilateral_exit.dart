import "dart:convert";

import "package:bitcoin_base/bitcoin_base.dart";
import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";
import "package:cw_bitcoin/electrum.dart";
import "package:cw_bitcoin/lightning/recover_funds_codec.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/utils/print_verbose.dart";

class UnilateralExitException extends CakeException {
  const UnilateralExitException(super.message);
}

/// One transaction of an exit, as the SDK's recovery describes it, with the txid of the
/// CPFP child that pays for it.
class UnilateralExitStep {
  UnilateralExitStep.fromTransaction(RecoveryTransaction transaction)
      : kind = transaction.kind,
        nodeId = transaction.nodeId,
        txid = transaction.txid,
        txHex = transaction.txHex,
        cpfpTxHex = transaction.cpfpTxHex,
        cpfpTxid = transaction.cpfpTxHex == null
            ? null
            : BtcTransaction.fromRaw(transaction.cpfpTxHex!).txId(),
        csvTimelockBlocks = transaction.csvTimelockBlocks,
        status = transaction.status;

  final RecoveryTxKind kind;
  final String? nodeId;
  final String txid;
  final String txHex;
  final String? cpfpTxHex;
  final String? cpfpTxid;
  final int? csvTimelockBlocks;
  final ExitTransactionStatus status;

  /// Tree transactions pay no fee and only relay as a package with their child.
  List<String> get rawTransactions => [txHex, if (cpfpTxHex != null) cpfpTxHex!];
}

/// Where an exit stands. An on-chain transaction never fails, so there is no failed state.
enum UnilateralExitStatus {
  /// The exit is on track: every step that can go out is on the network.
  active,

  /// A step the SDK reports ready was rejected and is not in the mempool, most likely
  /// because its fee is too low. Raising the fee rebuilds it.
  stalled,

  /// The chain no longer matches the recovery (the SDK's redo verdict), so it cannot
  /// finish as built. Building it again picks the funds up from wherever they are.
  rebuild,

  /// Every transaction has confirmed. The record stays as history.
  complete,
}

/// A unilateral exit in progress or done: the SDK's recovery, kept because the SDK does
/// not keep it and needs it back to follow the exit, plus what the wallet tracks around it.
class UnilateralExitPlan {
  const UnilateralExitPlan({
    required this.id,
    required this.recovery,
    required this.startedAtMs,
    required this.accountIndex,
    this.status = UnilateralExitStatus.active,
    this.inMempoolTxids = const {},
  });

  factory UnilateralExitPlan.start(RecoverFundsResponse recovery, {required int accountIndex}) {
    final startedAtMs = DateTime.now().millisecondsSinceEpoch;

    return UnilateralExitPlan(
      id: "$startedAtMs",
      recovery: recovery,
      startedAtMs: startedAtMs,
      accountIndex: accountIndex,
    );
  }

  factory UnilateralExitPlan.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;

    return UnilateralExitPlan(
      id: json["id"] as String,
      recovery: RecoverFundsCodec.fromJson(json["recovery"] as Map<String, dynamic>),
      startedAtMs: json["startedAtMs"] as int,
      accountIndex: json["accountIndex"] as int,
      status: UnilateralExitStatus.values.byName(json["status"] as String),
      inMempoolTxids: (json["inMempoolTxids"] as List).cast<String>().toSet(),
    );
  }

  /// Stays the same when the exit is rebuilt at a higher fee, so the record is replaced.
  final String id;

  final RecoverFundsResponse recovery;

  final int startedAtMs;

  final int accountIndex;

  final UnilateralExitStatus status;

  /// Steps the wallet has seen in the mempool, which the SDK cannot tell apart from ready.
  final Set<String> inMempoolTxids;

  List<UnilateralExitStep> get steps =>
      recovery.transactions.map(UnilateralExitStep.fromTransaction).toList();

  /// The leaves the exit recovers, named again when it is rebuilt.
  List<String> get leafIds => recovery.leaves.map((leaf) => leaf.leafId).toList();

  /// The wallet coins paying the exit's fees, as `txid:vout`.
  Set<String> get fundingOutpoints => {
        for (final input in recovery.fundingInputs)
          switch (input) {
            CpfpInput_P2wpkh(:final txid, :final vout) => "$txid:$vout",
            CpfpInput_P2tr(:final txid, :final vout) => "$txid:$vout",
            CpfpInput_Custom(:final txid, :final vout) => "$txid:$vout",
          },
      };

  /// Transactions whose outputs pay back to our funding script (the fan-out and the CPFP
  /// children), kept from regular sends while later steps spend them.
  Set<String> get fundingTxids => {
        for (final step in steps) ...[
          if (step.kind == RecoveryTxKind.fanOut) step.txid,
          if (step.cpfpTxid != null) step.cpfpTxid!,
        ],
      };

  /// What reaches the destination from the leaves that exit unilaterally: their value less
  /// the refund and sweep fees, which come out of it.
  int get sweptSat {
    final unilateralSat = recovery.leaves
        .where((leaf) => leaf.method == RecoveryMethod.unilateral)
        .fold(BigInt.zero, (sum, leaf) => sum + leaf.valueSats);

    return (unilateralSat - recovery.refundFeeSats - recovery.sweepFeeSats).toInt();
  }

  bool get isOngoing => status != UnilateralExitStatus.complete;

  UnilateralExitPlan copyWith({
    RecoverFundsResponse? recovery,
    UnilateralExitStatus? status,
    Set<String>? inMempoolTxids,
  }) =>
      UnilateralExitPlan(
        id: id,
        recovery: recovery ?? this.recovery,
        startedAtMs: startedAtMs,
        accountIndex: accountIndex,
        status: status ?? this.status,
        inMempoolTxids: inMempoolTxids ?? this.inMempoolTxids,
      );

  /// One history row per step, and one per fee payment that went out with a step, so the
  /// history shows what each transaction of the exit does and where it stands.
  List<UnilateralExitHistoryEntry> get historyEntries {
    final steps = this.steps;

    return [
      for (final (index, step) in steps.indexed) ...[
        UnilateralExitHistoryEntry(
          txid: step.txid,
          kind: UnilateralExitHistoryKind.values.byName(step.kind.name),
          stepNumber: index + 1,
          stepCount: steps.length,
          state: _stateOf(step),
          amountSat: _amountOf(step),
          timelockBlocks: step.csvTimelockBlocks,
          spendableAtHeight: switch (step.status) {
            ExitTransactionStatus_WaitingForTimelock(:final spendableAtHeight) => spendableAtHeight,
            _ => null,
          },
        ),
        if (step.cpfpTxid != null)
          UnilateralExitHistoryEntry(
            txid: step.cpfpTxid!,
            kind: UnilateralExitHistoryKind.fee,
            stepNumber: index + 1,
            stepCount: steps.length,
            // A fee payment only relays together with its step.
            state: _stateOf(step),
            amountSat: 0,
            timelockBlocks: null,
            spendableAtHeight: null,
          ),
      ],
    ];
  }

  int _amountOf(UnilateralExitStep step) => switch (step.kind) {
        RecoveryTxKind.sweep => sweptSat,
        RecoveryTxKind.cooperative => recovery.leaves
                .where((leaf) => leaf.leafId == step.nodeId)
                .firstOrNull
                ?.valueSats
                .toInt() ??
            0,
        _ => 0,
      };

  UnilateralExitStepState _stateOf(UnilateralExitStep step) {
    if (step.status is ExitTransactionStatus_Confirmed) {
      return UnilateralExitStepState.confirmed;
    }

    if (status == UnilateralExitStatus.rebuild) {
      return UnilateralExitStepState.rebuild;
    }

    return switch (step.status) {
      ExitTransactionStatus_Ready() => inMempoolTxids.contains(step.txid)
          ? UnilateralExitStepState.pending
          : status == UnilateralExitStatus.stalled
              ? UnilateralExitStepState.stalled
              : UnilateralExitStepState.waiting,
      ExitTransactionStatus_WaitingForTimelock() => UnilateralExitStepState.waitingForBlock,
      ExitTransactionStatus_Unverified() => UnilateralExitStepState.checking,
      _ => UnilateralExitStepState.waiting,
    };
  }

  String toJson() => jsonEncode({
        "id": id,
        "recovery": RecoverFundsCodec.toJson(recovery),
        "startedAtMs": startedAtMs,
        "accountIndex": accountIndex,
        "status": status.name,
        "inMempoolTxids": inMempoolTxids.toList(),
      });
}

/// What an exit transaction does, as its history row names it. The step kinds mirror the
/// SDK's [RecoveryTxKind]; [fee] is the CPFP child that pays for a step.
enum UnilateralExitHistoryKind { cooperative, fanOut, node, refund, sweep, fee }

enum UnilateralExitStepState {
  /// Waiting for the steps before it to confirm.
  waiting,

  /// Its inputs confirmed, but its timelock has not matured yet.
  waitingForBlock,

  /// The SDK could not read the chain for it; it is checked again on the next sync.
  checking,

  /// Ready, but rejected and not in the mempool, most likely for its fee.
  stalled,

  /// The exit has to be built again before this step can go out.
  rebuild,

  /// In the mempool.
  pending,

  confirmed,
}

class UnilateralExitHistoryEntry {
  const UnilateralExitHistoryEntry({
    required this.txid,
    required this.kind,
    required this.stepNumber,
    required this.stepCount,
    required this.state,
    required this.amountSat,
    required this.timelockBlocks,
    required this.spendableAtHeight,
  });

  final String txid;
  final UnilateralExitHistoryKind kind;
  final int stepNumber;
  final int stepCount;
  final UnilateralExitStepState state;

  /// What reaches this wallet: the swept or cooperatively recovered value, nothing for the
  /// other steps.
  final int amountSat;
  final int? timelockBlocks;
  final int? spendableAtHeight;

  /// The tags the app reads to title and explain the row. The names are shared with
  /// `SparkExitHistory` in the app as plain strings.
  Map<String, dynamic> get additionalInfo => {
        "isSparkExit": true,
        "sparkExitStep": kind.name,
        "sparkExitStepNumber": stepNumber,
        "sparkExitStepCount": stepCount,
        "sparkExitState": state.name,
        if (timelockBlocks != null) "sparkExitTimelockBlocks": timelockBlocks,
        if (spendableAtHeight != null) "sparkExitSpendableAtHeight": spendableAtHeight,
      };
}

class UnilateralExitProgress {
  const UnilateralExitProgress({
    required this.broadcastCount,
    required this.broadcastError,
    required this.isStalled,
    required this.inMempoolTxids,
  });

  /// Steps the server accepted on this tick.
  final int broadcastCount;

  /// The last rejection on this tick, if any.
  final String? broadcastError;

  /// A ready step was rejected and is not in the mempool.
  final bool isStalled;

  /// Ready steps the network holds after this tick.
  final Set<String> inMempoolTxids;
}

/// Sends every step the SDK reports ready. Sending one the network already has is
/// harmless, so this only skips what the server already knows.
class UnilateralExitBroadcaster {
  const UnilateralExitBroadcaster({required this.electrumClient});

  final ElectrumClient electrumClient;

  Future<UnilateralExitProgress> broadcastReady(UnilateralExitPlan plan) async {
    var broadcastCount = 0;
    String? broadcastError;
    var isStalled = false;
    final inMempoolTxids = <String>{};

    for (final step in plan.steps) {
      if (step.status is! ExitTransactionStatus_Ready) {
        continue;
      }

      if (await _isKnown(step.txid)) {
        inMempoolTxids.add(step.txid);
        continue;
      }

      try {
        await _broadcast(step);
        inMempoolTxids.add(step.txid);
        broadcastCount++;
        printV("unilateral exit: broadcast ${step.kind.name} ${step.txid}");
      } catch (e) {
        broadcastError = e.toString();
        isStalled = true;
        printV("unilateral exit: ${step.kind.name} ${step.txid} rejected: $e");
      }
    }

    return UnilateralExitProgress(
      broadcastCount: broadcastCount,
      broadcastError: broadcastError,
      isStalled: isStalled,
      inMempoolTxids: inMempoolTxids,
    );
  }

  Future<bool> _isKnown(String txid) async =>
      (await electrumClient.getTransactionVerbose(hash: txid)).isNotEmpty;

  Future<void> _broadcast(UnilateralExitStep step) async {
    if (step.cpfpTxHex != null) {
      return electrumClient.broadcastPackage(rawTransactions: step.rawTransactions);
    }

    final txid = await electrumClient.broadcastTransaction(transactionRaw: step.txHex);

    if (txid.isEmpty) {
      throw const UnilateralExitException("Transaction rejected by the server");
    }
  }
}
