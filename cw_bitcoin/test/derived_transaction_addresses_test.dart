import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_bitcoin/electrum_transaction_isolate.dart";
import "package:cw_bitcoin/input_ownership.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const network = BitcoinNetwork.mainnet;
  const walletType = WalletType.bitcoin;
  // Ownership only reads the pubkey from the witness, never verifies the sig.
  const dummySigHex = "00";

  final accountZeroPub = ECPrivate.random().getPublic();
  final accountZeroAddress = accountZeroPub.toP2wpkhAddress().toAddress(network);

  final accountOnePub = ECPrivate.random().getPublic();
  final accountOneAddress = accountOnePub.toP2wpkhAddress().toAddress(network);

  final externalAddress = ECPrivate.random().getPublic().toP2wpkhAddress();

  final addressesByAccount = {
    0: {accountZeroAddress},
    1: {accountOneAddress},
  };
  final allAddresses = {accountZeroAddress, accountOneAddress};

  // Send-all from account 1: one P2WPKH input, a single external output and
  // no change - the parent tx isn't fetched yet.
  BtcTransaction buildSendAllFromAccountOne() => BtcTransaction(
        inputs: [TxInput(txId: "22" * 32, txIndex: 0)],
        outputs: [
          TxOutput(amount: BigInt.from(4000), scriptPubKey: externalAddress.toScriptPubKey()),
        ],
        witnesses: [
          TxWitnessInput(stack: [dummySigHex, accountOnePub.toHex()]),
        ],
        hasSegwit: true,
      );

  group("DerivedTransactionAddresses.derive", () {
    test("records the owned address for a P2WPKH input and every output address", () {
      final derived =
          DerivedTransactionAddresses.derive(buildSendAllFromAccountOne(), allAddresses, network);

      expect(derived.inputOwnership.single.address, accountOneAddress);
      expect(derived.inputOwnership.single.isOwnedBy({accountOneAddress}), true);
      expect(derived.inputOwnership.single.isOwnedBy({accountZeroAddress}), false);
      expect(derived.outputAddresses, [externalAddress.toAddress(network)]);
    });

    test("an input revealing no pubkey (P2TR key-path) is unknown", () {
      final tx = BtcTransaction(
        inputs: [TxInput(txId: "22" * 32, txIndex: 0)],
        outputs: [
          TxOutput(amount: BigInt.from(4000), scriptPubKey: externalAddress.toScriptPubKey()),
        ],
        witnesses: [
          TxWitnessInput(stack: [dummySigHex]),
        ],
        hasSegwit: true,
      );

      final derived = DerivedTransactionAddresses.derive(tx, allAddresses, network);

      expect(derived.inputOwnership.single.address, null);
      expect(derived.inputOwnership.single.isOwnedBy(allAddresses), null);
    });
  });

  group("send-all with its parent tx not fetched", () {
    final bundle = ElectrumTransactionBundle(
      buildSendAllFromAccountOne(),
      ins: [null],
      confirmations: 1,
    );

    test("accountForTransaction attributes it to the input's account", () {
      final derived =
          DerivedTransactionAddresses.derive(bundle.originalTransaction, allAddresses, network);

      expect(
        accountForTransaction(bundle, derived, addressesByAccount, network, walletType),
        1,
      );
    });

    test("fromElectrumBundle records the owned input's address", () {
      final info = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {accountOneAddress},
      );

      expect(info.direction, TransactionDirection.outgoing);
      expect(info.inputAddresses, [accountOneAddress]);
    });

    test("building from precomputed derived addresses matches deriving inline", () {
      final derived =
          DerivedTransactionAddresses.derive(bundle.originalTransaction, allAddresses, network);

      final inline = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {accountOneAddress},
      );
      final precomputed = ElectrumTransactionInfo.fromElectrumBundle(
        bundle,
        walletType,
        network,
        addresses: {accountOneAddress},
        derived: derived,
      );

      expect(precomputed.direction, inline.direction);
      expect(precomputed.amount, inline.amount);
      expect(precomputed.inputAddresses, inline.inputAddresses);
      expect(precomputed.outputAddresses, inline.outputAddresses);
      expect(precomputed.inputsOwnershipFullyResolved, inline.inputsOwnershipFullyResolved);
    });
  });
}
