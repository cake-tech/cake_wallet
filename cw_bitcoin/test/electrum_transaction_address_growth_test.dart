import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_bitcoin/electrum_transaction_resolver.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

/// What happens to an already-built [ElectrumTransactionInfo] when the
/// wallet's address set later grows to include an address it spends from /
/// pays to.
void main() {
  const network = BitcoinNetwork.mainnet;
  const walletType = WalletType.bitcoin;
  const inputAAmount = 10000;
  const inputBAmount = 20000;
  const externalAmount = 25000;
  const changeAmount = 4000;

  final keyA = ECPrivate.random().getPublic();
  final keyB = ECPrivate.random().getPublic();
  final stranger = ECPrivate.random().getPublic();
  final addrA = keyA.toP2wpkhAddress().toAddress(network);
  final addrB = keyB.toP2wpkhAddress().toAddress(network);

  BtcTransaction parent(ECPublic key, int amount) => BtcTransaction(
        inputs: [],
        outputs: [
          TxOutput(
            amount: BigInt.from(amount),
            scriptPubKey: key.toP2wpkhAddress().toScriptPubKey(),
          ),
        ],
        hasSegwit: false,
      );

  final placeholderSig = "11" * 64;

  /// Spends one UTXO of A and one of B. [outputs] decide the output case.
  ElectrumTransactionInfo build(Set<String> addresses, List<TxOutput> outputs) {
    final tx = BtcTransaction(
      inputs: [TxInput(txId: "aa" * 32, txIndex: 0), TxInput(txId: "bb" * 32, txIndex: 0)],
      outputs: outputs,
      witnesses: [
        TxWitnessInput(stack: [placeholderSig, keyA.toHex()]),
        TxWitnessInput(stack: [placeholderSig, keyB.toHex()]),
      ],
      hasSegwit: true,
    );

    final bundle = ElectrumTransactionBundle(
      tx,
      ins: [parent(keyA, inputAAmount), parent(keyB, inputBAmount)],
      confirmations: 1,
    );

    return ElectrumTransactionInfo.fromElectrumBundle(
      bundle,
      walletType,
      network,
      addresses: addresses,
    );
  }

  TxOutput externalOut(int amount) => TxOutput(
        amount: BigInt.from(amount),
        scriptPubKey: stranger.toP2pkhAddress().toScriptPubKey(),
      );

  TxOutput outTo(ECPublic key, int amount) =>
      TxOutput(amount: BigInt.from(amount), scriptPubKey: key.toP2wpkhAddress().toScriptPubKey());

  List<dynamic> ownedInputs(ElectrumTransactionInfo i) =>
      i.additionalInfo["ownedInputs"] as List<dynamic>;

  List<dynamic> ownedOutputs(ElectrumTransactionInfo i) =>
      i.additionalInfo["ownedOutputs"] as List<dynamic>;

  group("input becomes owned when the address set grows", () {
    final outputs = [externalOut(externalAmount)];
    final set1 = {addrA};
    final set2 = {addrA, addrB};

    test("rebuilding with the larger set picks up the new input", () {
      final before = build(set1, outputs);
      final after = build(set2, outputs);

      expect(ownedInputs(before).length, 1);
      expect(ownedInputs(after).length, 2);

      expect(before.direction, TransactionDirection.outgoing);
      expect(after.direction, TransactionDirection.outgoing);

      // partial ownership: owned input total minus owned change; full ownership: the payout
      expect(before.amount.amount.toInt(), inputAAmount);
      expect(after.amount.amount.toInt(), externalAmount);
    });

    test("needsAddressRecheck flags the stale tx once its other input is ours", () {
      final stale = build(set1, outputs);
      expect(ElectrumTransactionResolver.needsAddressRecheck(stale, set2), isTrue);
    });

    test("needsAddressRecheck leaves it alone when the set did not change", () {
      final info = build(set2, outputs);
      expect(ElectrumTransactionResolver.needsAddressRecheck(info, set2), isFalse);
    });
  });

  group("output becomes owned when the address set grows", () {
    // A is spent either way; B only receives the change.
    final outputs = [externalOut(externalAmount), outTo(keyB, changeAmount)];
    final set1 = {addrA};
    final set2 = {addrA, addrB};

    test("rebuilding with the larger set picks up the new output", () {
      final before = build(set1, outputs);
      final after = build(set2, outputs);

      expect(ownedOutputs(before), isEmpty);
      expect(ownedOutputs(after).length, 1);
      expect(ownedOutputs(after).single["address"], addrB);
    });

    test("needsAddressRecheck flags the stale tx once the output address is ours", () {
      final stale = build(set1, outputs);
      expect(ElectrumTransactionResolver.needsAddressRecheck(stale, set2), isTrue);
    });

    test("pure receive: new output address flags a recheck", () {
      final receiveOnly = [outTo(keyB, changeAmount)];
      final stale = build({}, receiveOnly);
      expect(ElectrumTransactionResolver.needsAddressRecheck(stale, {addrB}), isTrue);
    });
  });

  group("address set size", () {
    test("is recorded at build time", () {
      final info = build({addrA}, [externalOut(externalAmount)]);
      expect(info.additionalInfo["addressSetSizeKey"], 1);
    });

    test("a larger set triggers a recheck even with no output or empty-input hint", () {
      final info = build({addrA}, [externalOut(externalAmount)]);
      expect(ElectrumTransactionResolver.needsAddressRecheck(info, {addrA, addrB}), isTrue);
      expect(ElectrumTransactionResolver.needsAddressRecheck(info, {addrA}), isFalse);
    });

    test("legacy txs without the count fall back to the output heuristic", () {
      final legacy = build({addrA}, [externalOut(externalAmount), outTo(keyB, changeAmount)]);
      legacy.additionalInfo.remove("addressSetSizeKey");
      expect(ElectrumTransactionResolver.needsAddressRecheck(legacy, {addrA, addrB}), isTrue);
      expect(ElectrumTransactionResolver.needsAddressRecheck(legacy, {addrA}), isFalse);
    });
  });

  group("isStaleForAddress: txs found in a (new) address's own history", () {
    test("input of an address the tx didn't know yet is stale, then settled once rebuilt", () {
      final outputs = [externalOut(externalAmount)];
      final stale = build({addrA}, outputs);

      expect(ElectrumTransactionResolver.isStaleForAddress(stale, addrB), isTrue);
      // A was known when it was classified.
      expect(ElectrumTransactionResolver.isStaleForAddress(stale, addrA), isFalse);

      final rebuilt = build({addrA, addrB}, outputs);
      expect(ElectrumTransactionResolver.isStaleForAddress(rebuilt, addrB), isFalse);
    });

    test("output to an address the tx didn't know yet is stale, then settled once rebuilt", () {
      final outputs = [externalOut(externalAmount), outTo(keyB, changeAmount)];
      final stale = build({addrA}, outputs);

      expect(ElectrumTransactionResolver.isStaleForAddress(stale, addrB), isTrue);

      final rebuilt = build({addrA, addrB}, outputs);
      expect(ElectrumTransactionResolver.isStaleForAddress(rebuilt, addrB), isFalse);
    });

    test("an unresolved tx has no recorded inputs to compare, so inputs never flag it", () {
      final tx = BtcTransaction(
        inputs: [TxInput(txId: "aa" * 32, txIndex: 0)],
        outputs: [externalOut(externalAmount)],
        witnesses: [
          TxWitnessInput(stack: [placeholderSig, keyA.toHex()]),
        ],
        hasSegwit: true,
      );
      final firstPass = ElectrumTransactionInfo.fromElectrumBundle(
        ElectrumTransactionBundle(tx, ins: [null], confirmations: 1),
        walletType,
        network,
        addresses: {addrA},
      );

      expect(firstPass.inputsOwnershipFullyResolved, isFalse);
      expect(ElectrumTransactionResolver.isStaleForAddress(firstPass, addrB), isFalse);
    });
  });
}
