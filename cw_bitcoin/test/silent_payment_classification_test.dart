import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/bitcoin_address_record.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

/// A spend of a received Silent Payment coin must be classified as a send. The
/// coin's P2TR output address is only in silentAddresses, so classification
/// has to look there too.
void main() {
  const network = BitcoinNetwork.mainnet;

  final walletKey = ECPrivate.random().getPublic();
  final walletAddress = walletKey.toP2wpkhAddress().toAddress(network);
  final spOutputKey = ECPrivate.random().getPublic();
  final spOutputAddress = spOutputKey.toTaprootAddress().toAddress(network);

  BitcoinAddressRecord walletRecord(String address, {BitcoinAddressType? type, int account = 0}) =>
      BitcoinAddressRecord(
        address,
        index: 0,
        accountIndex: account,
        type: type ?? SegwitAddresType.p2wpkh,
        network: network,
      );

  BitcoinSilentPaymentAddressRecord silentRecord(String address, BitcoinAddressType type) =>
      BitcoinSilentPaymentAddressRecord(
        address,
        index: 0,
        silentPaymentTweak: null,
        network: network,
        type: type,
      );

  group("a spend of a received Silent Payment coin", () {
    const spent = 150000;
    const sentAway = 100000;
    const change = 49000;

    // The SP coin: a P2TR output the scanner found and recorded.
    final parent = BtcTransaction(
      inputs: [TxInput(txId: "cc" * 32, txIndex: 0)],
      outputs: [
        TxOutput(
          amount: BigInt.from(spent),
          scriptPubKey: spOutputKey.toTaprootAddress().toScriptPubKey(),
        ),
      ],
      hasSegwit: false,
    );

    // A key-path P2TR spend carries only a signature, so ownership comes from
    // the parent's output address, not from the witness.
    final spend = BtcTransaction(
      inputs: [TxInput(txId: "aa" * 32, txIndex: 0)],
      outputs: [
        TxOutput(
          amount: BigInt.from(sentAway),
          scriptPubKey: ECPrivate.random().getPublic().toP2wpkhAddress().toScriptPubKey(),
        ),
        TxOutput(
          amount: BigInt.from(change),
          scriptPubKey: walletKey.toP2wpkhAddress().toScriptPubKey(),
        ),
      ],
      witnesses: [
        TxWitnessInput(stack: ["11" * 64]),
      ],
      hasSegwit: true,
    );

    ElectrumTransactionInfo classify(Set<String> addresses) =>
        ElectrumTransactionInfo.fromElectrumBundle(
          ElectrumTransactionBundle(spend, ins: [parent], confirmations: 3),
          WalletType.bitcoin,
          network,
          addresses: addresses,
        );

    test("is a send of the amount that left the wallet", () {
      final info = classify({walletAddress, spOutputAddress});

      expect(info.direction, TransactionDirection.outgoing);
      expect(info.amount.amount, BigInt.from(sentAway));
      expect(info.isAmountPending, isFalse);
    });

    test("without the received outputs it reads as receiving the change", () {
      // The bug this set fixes: classified against the wallet's addresses only.
      final info = classify({walletAddress});

      expect(info.direction, TransactionDirection.incoming);
      expect(info.amount.amount, BigInt.from(change));
    });
  });
}
