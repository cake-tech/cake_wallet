import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("ElectrumTransactionInfo.fromElectrumBundle inputsOwnershipFullyResolved", () {
    const network = BitcoinNetwork.mainnet;
    const walletType = WalletType.bitcoin;
    const spentAmount = 5000;

    final ownerPriv = ECPrivate.random();
    final ownerPub = ownerPriv.getPublic();
    final ownedAddress = ownerPub.toP2wpkhAddress().toAddress(network);
    final ownedPubkeyHex = ownerPub.toHex();
    final ownerScriptCode = ownerPub.toP2pkhAddress().toScriptPubKey();

    final strangerPriv = ECPrivate.random();
    final strangerPub = strangerPriv.getPublic();
    final strangerPubkeyHex = strangerPub.toHex();
    final strangerScriptCode = strangerPub.toP2pkhAddress().toScriptPubKey();

    TxOutput spendableOutput() =>
        TxOutput(amount: BigInt.from(spentAmount), scriptPubKey: Script(script: ["OP_RETURN"]));

    BtcTransaction buildTxWithEmptyWitness() {
      final input = TxInput(txId: "22" * 32, txIndex: 0);
      return BtcTransaction(
        inputs: [input],
        outputs: [spendableOutput()],
        witnesses: [TxWitnessInput(stack: [])],
        hasSegwit: true,
      );
    }

    BtcTransaction withWitness(BtcTransaction tx, List<String> stack) => tx.copyWith(
          witnesses: [TxWitnessInput(stack: stack)],
        );

    String signAsWitness(ECPrivate priv, Script scriptCode) {
      final digest = buildTxWithEmptyWitness().getTransactionSegwitDigit(
        txInIndex: 0,
        script: scriptCode,
        amount: BigInt.from(spentAmount),
      );
      return priv.signInput(digest);
    }

    test(
        "all inputs confirmed not ours -> inputsOwnershipFullyResolved true, fee stays null, no fetch needed",
        () {
      final sigHex = signAsWitness(strangerPriv, strangerScriptCode);
      final tx = withWitness(buildTxWithEmptyWitness(), [sigHex, strangerPubkeyHex]);
      final bundle = ElectrumTransactionBundle(tx, ins: [null], confirmations: 1);

      final info = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {ownedAddress},
      );

      expect(info.additionalInfo["inputsOwnershipFullyResolved"], true);
      expect(info.fee, null);
    });

    test("owned input, parent tx not fetched -> inputsOwnershipFullyResolved false, fee stays null",
        () {
      final sigHex = signAsWitness(ownerPriv, ownerScriptCode);
      final tx = withWitness(buildTxWithEmptyWitness(), [sigHex, ownedPubkeyHex]);
      final bundle = ElectrumTransactionBundle(tx, ins: [null], confirmations: 1);

      final info = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {ownedAddress},
      );

      expect(info.additionalInfo["inputsOwnershipFullyResolved"], false);
      expect(info.fee, null);
      expect(info.direction, TransactionDirection.outgoing);
    });

    test("same owned input, parent tx fetched -> inputsOwnershipFullyResolved true, fee populated",
        () {
      final sigHex = signAsWitness(ownerPriv, ownerScriptCode);
      final tx = withWitness(buildTxWithEmptyWitness(), [sigHex, ownedPubkeyHex]);

      const parentOutputAmount = spentAmount + 300;
      final parentTx = BtcTransaction(
        inputs: [],
        outputs: [
          TxOutput(
            amount: BigInt.from(parentOutputAmount),
            scriptPubKey: Script(script: ["OP_RETURN"]),
          ),
        ],
        hasSegwit: false,
      );
      final bundle = ElectrumTransactionBundle(tx, ins: [parentTx], confirmations: 1);

      final info = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {ownedAddress},
      );

      expect(info.additionalInfo["inputsOwnershipFullyResolved"], true);
      expect(info.fee?.amount.toInt(), 300);
    });

    test(
        "pass 3: received tx, parent tx fetched -> inputsOwnershipFullyResolved stays true, fee gets populated",
        () {
      final sigHex = signAsWitness(strangerPriv, strangerScriptCode);
      final tx = withWitness(buildTxWithEmptyWitness(), [sigHex, strangerPubkeyHex]);

      const parentOutputAmount = spentAmount + 150;
      final parentTx = BtcTransaction(
        inputs: [],
        outputs: [
          TxOutput(
            amount: BigInt.from(parentOutputAmount),
            scriptPubKey: Script(script: ["OP_RETURN"]),
          ),
        ],
        hasSegwit: false,
      );
      final bundle = ElectrumTransactionBundle(tx, ins: [parentTx], confirmations: 1);

      final info = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {ownedAddress},
      );

      expect(info.additionalInfo["inputsOwnershipFullyResolved"], true);
      expect(info.fee?.amount.toInt(), 150);
      expect(info.direction, TransactionDirection.incoming);
    });

    // Coinjoin, payjoin, etc...
    test(
        "partial ownership: amount is our own input minus our own change,"
        " not the whole transaction's payout", () {
      const ownedInputAmount = 33554432;
      const strangerInputAmount = 1800000000;
      const externalOutputAmount = 1890000000;
      final placeholderSig = "11" * 64;

      final ownedInput = TxInput(txId: "aa" * 32, txIndex: 0);
      final strangerInput = TxInput(txId: "bb" * 32, txIndex: 0);

      final tx = BtcTransaction(
        inputs: [ownedInput, strangerInput],
        outputs: [
          TxOutput(amount: BigInt.from(externalOutputAmount), scriptPubKey: strangerScriptCode),
        ],
        witnesses: [
          TxWitnessInput(stack: [placeholderSig, ownedPubkeyHex]),
          TxWitnessInput(stack: [placeholderSig, strangerPubkeyHex]),
        ],
        hasSegwit: true,
      );

      final ownedParentTx = BtcTransaction(
        inputs: [],
        outputs: [
          TxOutput(
            amount: BigInt.from(ownedInputAmount),
            scriptPubKey: ownerPub.toP2wpkhAddress().toScriptPubKey(),
          ),
        ],
        hasSegwit: false,
      );
      final strangerParentTx = BtcTransaction(
        inputs: [],
        outputs: [
          TxOutput(amount: BigInt.from(strangerInputAmount), scriptPubKey: strangerScriptCode),
        ],
        hasSegwit: false,
      );

      final bundle = ElectrumTransactionBundle(
        tx,
        ins: [ownedParentTx, strangerParentTx],
        confirmations: 1,
      );

      final info = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {ownedAddress},
      );

      expect(info.direction, TransactionDirection.outgoing);
      expect(info.amount.amount.toInt(), ownedInputAmount);
    });

    test(
        "partial ownership, only the owned input resolved so far (e.g. a "
        "slow initial sync that hasn't fetched the rest yet): amount is "
        "already the safe partial total, not the wrong external-payout sum", () {
      const ownedInputAmount = 33554432;
      const externalOutputAmount = 1890000000;
      final placeholderSig = "11" * 64;

      final ownedInput = TxInput(txId: "aa" * 32, txIndex: 0);
      final strangerInput = TxInput(txId: "bb" * 32, txIndex: 0);

      final tx = BtcTransaction(
        inputs: [ownedInput, strangerInput],
        outputs: [
          TxOutput(amount: BigInt.from(externalOutputAmount), scriptPubKey: strangerScriptCode),
        ],
        witnesses: [
          TxWitnessInput(stack: [placeholderSig, ownedPubkeyHex]),
          TxWitnessInput(stack: [placeholderSig, strangerPubkeyHex]),
        ],
        hasSegwit: true,
      );

      final ownedParentTx = BtcTransaction(
        inputs: [],
        outputs: [
          TxOutput(
            amount: BigInt.from(ownedInputAmount),
            scriptPubKey: ownerPub.toP2wpkhAddress().toScriptPubKey(),
          ),
        ],
        hasSegwit: false,
      );

      // strangerInput's parent is NOT fetched yet - only [ownedParentTx] is
      // given, at strangerInput's position left null.
      final bundle = ElectrumTransactionBundle(
        tx,
        ins: [ownedParentTx, null],
        confirmations: 1,
      );

      final info = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {ownedAddress},
      );

      expect(info.direction, TransactionDirection.outgoing);
      expect(info.additionalInfo["inputsOwnershipFullyResolved"], false);
      expect(info.amount.amount.toInt(), ownedInputAmount);
    });

    test(
        "unknown-ownership input (taproot key-path witness, sig only), parent not fetched -> inputsOwnershipFullyResolved false",
        () {
      final sigHex = signAsWitness(ownerPriv, ownerScriptCode);
      final tx = withWitness(buildTxWithEmptyWitness(), [sigHex]);
      final bundle = ElectrumTransactionBundle(tx, ins: [null], confirmations: 1);

      final info = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {ownedAddress},
      );

      expect(info.additionalInfo["inputsOwnershipFullyResolved"], false);
      expect(info.fee, null);
    });
  });
}
