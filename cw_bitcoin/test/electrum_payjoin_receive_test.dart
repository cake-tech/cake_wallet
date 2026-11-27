import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

/// A payjoin receive that pays only the receiver: the receiver co-spends one
/// of their own coins, so the amount received is the net of what they put in.
void main() {
  const network = BitcoinNetwork.mainnet;
  const ownCoin = 60000;
  const senderCoin = 50000;
  const paid = 109000;

  final ownPublicKey = ECPrivate.random().getPublic();
  final ownAddress = ownPublicKey.toP2wpkhAddress();
  final senderAddress = ECPrivate.random().getPublic().toP2wpkhAddress();

  BtcTransaction parentPaying(String address, int amount) => BtcTransaction(
        inputs: [TxInput(txId: "cc" * 32, txIndex: 0)],
        outputs: [
          TxOutput(
            amount: BigInt.from(amount),
            scriptPubKey: (address == ownAddress.toAddress(network) ? ownAddress : senderAddress)
                .toScriptPubKey(),
          ),
        ],
      );

  final ownParent = parentPaying(ownAddress.toAddress(network), ownCoin);
  final senderParent = parentPaying(senderAddress.toAddress(network), senderCoin);

  // A P2WPKH spend reveals the spender's key, so ownership of the first input
  // is known without fetching its parent; the sender's input is a P2TR
  // key-path spend, which reveals nothing.
  final payjoin = BtcTransaction(
    hasSegwit: true,
    witnesses: [
      TxWitnessInput(stack: ["11" * 71, ownPublicKey.toHex()]),
      TxWitnessInput(stack: ["22" * 64]),
    ],
    inputs: [
      TxInput(txId: ownParent.txId(), txIndex: 0),
      TxInput(txId: senderParent.txId(), txIndex: 0),
    ],
    outputs: [
      TxOutput(amount: BigInt.from(paid), scriptPubKey: ownAddress.toScriptPubKey()),
    ],
  );

  ElectrumTransactionInfo classify({required bool parentsFetched}) =>
      ElectrumTransactionInfo.fromElectrumBundle(
        ElectrumTransactionBundle(
          payjoin,
          ins: parentsFetched ? [ownParent, senderParent] : [null, null],
          confirmations: 1,
        ),
        WalletType.bitcoin,
        network,
        addresses: {ownAddress.toAddress(network)},
      );

  test("a payjoin that pays only us shows the net received, not the full output", () {
    final info = classify(parentsFetched: true);

    expect(info.direction, TransactionDirection.incoming);
    expect(info.amount.amount, BigInt.from(paid - ownCoin));
    expect(info.isAmountPending, isFalse);
  });

  test("the amount stays pending until our co-spent input is resolved", () {
    final info = classify(parentsFetched: false);

    expect(info.isAmountPending, isTrue);
  });

  test("when the other party adds less than the fee it is a send of the loss, not a receive", () {
    final tinyParent = parentPaying(senderAddress.toAddress(network), 500);
    final lossy = BtcTransaction(
      hasSegwit: true,
      witnesses: [
        TxWitnessInput(stack: ["11" * 71, ownPublicKey.toHex()]),
        TxWitnessInput(stack: ["22" * 64]),
      ],
      inputs: [
        TxInput(txId: ownParent.txId(), txIndex: 0),
        TxInput(txId: tinyParent.txId(), txIndex: 0),
      ],
      outputs: [
        TxOutput(amount: BigInt.from(59000), scriptPubKey: ownAddress.toScriptPubKey()),
      ],
    );

    final info = ElectrumTransactionInfo.fromElectrumBundle(
      ElectrumTransactionBundle(lossy, ins: [ownParent, tinyParent], confirmations: 1),
      WalletType.bitcoin,
      network,
      addresses: {ownAddress.toAddress(network)},
    );

    // 60,000 + 500 in, 59,000 out: we put in 60,000 and got 59,000 back.
    expect(info.direction, TransactionDirection.outgoing);
    expect(info.amount.amount, BigInt.from(1000));
    expect(info.isAmountPending, isFalse);
  });
}
