import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// First-pass (no parents fetched) classification must not present an
/// undecidable spend as a settled receive.
void main() {
  const network = BitcoinNetwork.mainnet;
  const walletType = WalletType.bitcoin;
  const parentAmount = 50000;
  const externalAmount = 30000;
  const changeAmount = 19000;

  final ours = ECPrivate.random().getPublic();
  final stranger = ECPrivate.random().getPublic();
  final ourAddress = ours.toP2wpkhAddress().toAddress(network);
  final placeholderSig = "11" * 64;

  final outputs = [
    TxOutput(
      amount: BigInt.from(externalAmount),
      scriptPubKey: stranger.toP2wpkhAddress().toScriptPubKey(),
    ),
    TxOutput(
      amount: BigInt.from(changeAmount),
      scriptPubKey: ours.toP2wpkhAddress().toScriptPubKey(),
    ),
  ];

  // A bare 64-byte signature in the witness (P2TR key-path) says nothing
  // about whose key signed it.
  BtcTransaction taprootKeyPathSpend() => BtcTransaction(
        inputs: [TxInput(txId: "aa" * 32, txIndex: 0)],
        outputs: outputs,
        witnesses: [
          TxWitnessInput(stack: [placeholderSig]),
        ],
        hasSegwit: true,
      );

  BtcTransaction parent() => BtcTransaction(
        inputs: [],
        outputs: [
          TxOutput(
            amount: BigInt.from(parentAmount),
            scriptPubKey: ours.toP2wpkhAddress().toScriptPubKey(),
          ),
        ],
        hasSegwit: false,
      );

  ElectrumTransactionInfo build(BtcTransaction tx, List<BtcTransaction?> ins) =>
      ElectrumTransactionInfo.fromElectrumBundle(
        ElectrumTransactionBundle(tx, ins: ins, confirmations: 1),
        walletType,
        network,
        addresses: {ourAddress},
      );

  test("unresolved P2TR-style input: amount is pending, not a settled receive", () {
    final info = build(taprootKeyPathSpend(), [null]);

    // Undecidable without the parent, so it keeps the default direction...
    expect(info.direction, TransactionDirection.incoming);

    // ...but must not be presented as final.
    expect(info.isAmountPending, isTrue);
    expect(info.needsResolution, isTrue);
  });

  test("once the parent is resolved the tx is a settled send", () {
    final info = build(taprootKeyPathSpend(), [parent()]);

    expect(info.direction, TransactionDirection.outgoing);
    expect(info.fee, isNotNull);
    expect(info.isAmountPending, isFalse);
  });

  test("a receive from inputs confirmed not ours is settled without parents", () {
    final tx = BtcTransaction(
      inputs: [TxInput(txId: "aa" * 32, txIndex: 0)],
      outputs: outputs,
      witnesses: [
        TxWitnessInput(stack: [placeholderSig, stranger.toHex()]),
      ],
      hasSegwit: true,
    );

    final info = build(tx, [null]);

    expect(info.direction, TransactionDirection.incoming);
    expect(info.isAmountPending, isFalse);
  });
}
