import "package:breez_sdk_spark_flutter/breez_sdk_spark.dart";

/// Stores a [RecoverFundsResponse] as JSON. The SDK does not keep a recovery, and
/// `checkRecoverFunds` needs it back to follow the recovery to its end.
class RecoverFundsCodec {
  static Map<String, dynamic> toJson(RecoverFundsResponse recovery) => {
        "recoverableValueSats": "${recovery.recoverableValueSats}",
        "totalFeeSats": "${recovery.totalFeeSats}",
        "cooperativeFeeSats": "${recovery.cooperativeFeeSats}",
        "cpfpFeeSats": "${recovery.cpfpFeeSats}",
        "fanoutFeeSats": "${recovery.fanoutFeeSats}",
        "refundFeeSats": "${recovery.refundFeeSats}",
        "sweepFeeSats": "${recovery.sweepFeeSats}",
        "leaves": [
          for (final leaf in recovery.leaves)
            {"leafId": leaf.leafId, "valueSats": "${leaf.valueSats}", "method": leaf.method.name},
        ],
        "transactions": [
          for (final transaction in recovery.transactions)
            {
              "kind": transaction.kind.name,
              "nodeId": transaction.nodeId,
              "txid": transaction.txid,
              "txHex": transaction.txHex,
              "cpfpTxHex": transaction.cpfpTxHex,
              "csvTimelockBlocks": transaction.csvTimelockBlocks,
              "dependsOn": transaction.dependsOn,
              "status": _statusToJson(transaction.status),
            },
        ],
        "fundingInputs": [for (final input in recovery.fundingInputs) _fundingInputToJson(input)],
        "feeRateSatPerVbyte": "${recovery.feeRateSatPerVbyte}",
        "destination": recovery.destination,
      };

  /// Leaves that the operators failed to co-sign are not part of the recovery (they need one of
  /// their own), so they are not stored and come back empty.
  static RecoverFundsResponse fromJson(Map<String, dynamic> json) => RecoverFundsResponse(
        recoverableValueSats: BigInt.parse(json["recoverableValueSats"] as String),
        totalFeeSats: BigInt.parse(json["totalFeeSats"] as String),
        cooperativeFeeSats: BigInt.parse(json["cooperativeFeeSats"] as String),
        cpfpFeeSats: BigInt.parse(json["cpfpFeeSats"] as String),
        fanoutFeeSats: BigInt.parse(json["fanoutFeeSats"] as String),
        refundFeeSats: BigInt.parse(json["refundFeeSats"] as String),
        sweepFeeSats: BigInt.parse(json["sweepFeeSats"] as String),
        leaves: [
          for (final leaf in (json["leaves"] as List).cast<Map<String, dynamic>>())
            RecoverFundsLeaf(
              leafId: leaf["leafId"] as String,
              valueSats: BigInt.parse(leaf["valueSats"] as String),
              method: RecoveryMethod.values.byName(leaf["method"] as String),
            ),
        ],
        failed: const [],
        transactions: [
          for (final transaction in (json["transactions"] as List).cast<Map<String, dynamic>>())
            RecoveryTransaction(
              kind: RecoveryTxKind.values.byName(transaction["kind"] as String),
              nodeId: transaction["nodeId"] as String?,
              txid: transaction["txid"] as String,
              txHex: transaction["txHex"] as String,
              cpfpTxHex: transaction["cpfpTxHex"] as String?,
              csvTimelockBlocks: transaction["csvTimelockBlocks"] as int?,
              dependsOn: (transaction["dependsOn"] as List).cast<String>(),
              status: _statusFromJson(transaction["status"] as Map<String, dynamic>),
            ),
        ],
        fundingInputs: [
          for (final input in (json["fundingInputs"] as List).cast<Map<String, dynamic>>())
            _fundingInputFromJson(input),
        ],
        feeRateSatPerVbyte: BigInt.parse(json["feeRateSatPerVbyte"] as String),
        destination: json["destination"] as String,
      );

  static Map<String, dynamic> _statusToJson(ExitTransactionStatus status) => switch (status) {
        ExitTransactionStatus_Confirmed(:final blockHeight) => {
            "type": "confirmed",
            "blockHeight": blockHeight,
          },
        ExitTransactionStatus_Ready() => {"type": "ready"},
        ExitTransactionStatus_WaitingForDependencies() => {"type": "waitingForDependencies"},
        ExitTransactionStatus_WaitingForTimelock(:final spendableAtHeight) => {
            "type": "waitingForTimelock",
            "spendableAtHeight": spendableAtHeight,
          },
        ExitTransactionStatus_Unverified() => {"type": "unverified"},
      };

  static ExitTransactionStatus _statusFromJson(Map<String, dynamic> json) =>
      switch (json["type"] as String) {
        "confirmed" => ExitTransactionStatus.confirmed(blockHeight: json["blockHeight"] as int?),
        "ready" => const ExitTransactionStatus.ready(),
        "waitingForDependencies" => const ExitTransactionStatus.waitingForDependencies(),
        "waitingForTimelock" => ExitTransactionStatus.waitingForTimelock(
            spendableAtHeight: json["spendableAtHeight"] as int?,
          ),
        _ => const ExitTransactionStatus.unverified(),
      };

  static Map<String, dynamic> _fundingInputToJson(CpfpInput input) => switch (input) {
        CpfpInput_P2wpkh(:final txid, :final vout, :final valueSats, :final pubkey) => {
            "type": "p2wpkh",
            "txid": txid,
            "vout": vout,
            "valueSats": "$valueSats",
            "pubkey": pubkey,
          },
        CpfpInput_P2tr(:final txid, :final vout, :final valueSats, :final pubkey) => {
            "type": "p2tr",
            "txid": txid,
            "vout": vout,
            "valueSats": "$valueSats",
            "pubkey": pubkey,
          },
        CpfpInput_Custom(
          :final txid,
          :final vout,
          :final valueSats,
          :final scriptPubkeyHex,
          :final signedInputWeight,
        ) =>
          {
            "type": "custom",
            "txid": txid,
            "vout": vout,
            "valueSats": "$valueSats",
            "scriptPubkeyHex": scriptPubkeyHex,
            "signedInputWeight": "$signedInputWeight",
          },
      };

  static CpfpInput _fundingInputFromJson(Map<String, dynamic> json) {
    final txid = json["txid"] as String;
    final vout = json["vout"] as int;
    final valueSats = BigInt.parse(json["valueSats"] as String);

    return switch (json["type"] as String) {
      "p2tr" => CpfpInput.p2Tr(
          txid: txid,
          vout: vout,
          valueSats: valueSats,
          pubkey: json["pubkey"] as String,
        ),
      "custom" => CpfpInput.custom(
          txid: txid,
          vout: vout,
          valueSats: valueSats,
          scriptPubkeyHex: json["scriptPubkeyHex"] as String,
          signedInputWeight: BigInt.parse(json["signedInputWeight"] as String),
        ),
      _ => CpfpInput.p2Wpkh(
          txid: txid,
          vout: vout,
          valueSats: valueSats,
          pubkey: json["pubkey"] as String,
        ),
    };
  }
}
