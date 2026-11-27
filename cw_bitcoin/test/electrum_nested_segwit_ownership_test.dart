import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

import "raw_tx_hex.dart";

/// A spend from a P2SH-P2WPKH (nested segwit) address, read from the raw hex
/// the way the Electrum sync reads it. Before the parent transaction is fetched,
/// the only ownership evidence is the witness, so a witness that bitcoin_base
/// drops leaves the input unknown.
void main() {
  const network = BitcoinNetwork.mainnet;
  final key = ECPrivate.random().getPublic();
  final walletAddress = key.toP2wpkhInP2sh().toAddress(network);

  final sig = "11" * 71;
  final nestedScriptSig = "16" "0014${"22" * 20}";
  final rawHex = rawTxHex(
    inputs: [RawInput(txid: "aa" * 32, scriptSig: nestedScriptSig)],
    outputs: [RawOutput(amount: 40000, scriptPubKey: "0014${"33" * 20}")],
    witnesses: [
      [sig, key.toHex()],
    ],
  );

  test("a nested-segwit spend is seen as ours from its witness, before any parent is fetched", () {
    final info = ElectrumTransactionInfo.fromElectrumBundle(
      ElectrumTransactionBundle(
        BtcTransaction.fromRaw(rawHex),
        ins: [null],
        confirmations: 10,
      ),
      WalletType.bitcoin,
      network,
      addresses: {walletAddress},
    );

    expect(info.direction, TransactionDirection.outgoing);
    expect(info.inputAddresses, contains(walletAddress));
  });

  test("a nested-segwit spend from another wallet is not claimed as ours", () {
    final stranger = ECPrivate.random().getPublic().toP2wpkhInP2sh().toAddress(network);

    final info = ElectrumTransactionInfo.fromElectrumBundle(
      ElectrumTransactionBundle(
        BtcTransaction.fromRaw(rawHex),
        ins: [null],
        confirmations: 10,
      ),
      WalletType.bitcoin,
      network,
      addresses: {stranger},
    );

    expect(info.inputAddresses, isNot(contains(walletAddress)));
    expect(info.direction, isNot(TransactionDirection.outgoing));
  });

  test("a parsed nested-segwit spend reports its full virtual size, so the fee rate isn't inflated",
      () {
    // vsize = (base size * 3 + total size) / 4, rounded up. A parse that drops
    // the witness shrinks the total size and so undercounts the vsize.
    final baseSize = rawTxHex(
          inputs: [RawInput(txid: "aa" * 32, scriptSig: nestedScriptSig)],
          outputs: [RawOutput(amount: 40000, scriptPubKey: "0014${"33" * 20}")],
        ).length ~/
        2;
    final totalSize = rawHex.length ~/ 2;
    final expected = (baseSize * 3 + totalSize + 3) ~/ 4;

    expect(ElectrumTransactionInfo.virtualSize(BtcTransaction.fromRaw(rawHex)), expected);
  });
}
