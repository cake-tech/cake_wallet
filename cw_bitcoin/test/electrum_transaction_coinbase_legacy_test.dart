import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

/// A coinbase payout has no parent transaction to fetch, and the history
/// records written before this change have no ownership flags. Both must load
/// without staying "Loading..." forever.
void main() {
  const network = BitcoinNetwork.mainnet;
  const walletType = WalletType.bitcoin;
  const payout = 1500000;

  final key = ECPrivate.random().getPublic();
  final walletAddress = key.toP2wpkhAddress().toAddress(network);

  ElectrumTransactionInfo coinbasePayout() {
    final tx = BtcTransaction(
      inputs: [TxInput(txId: "00" * 32, txIndex: 0xffffffff)],
      outputs: [
        TxOutput(
          amount: BigInt.from(payout),
          scriptPubKey: key.toP2wpkhAddress().toScriptPubKey(),
        ),
      ],
      hasSegwit: false,
    );

    return ElectrumTransactionInfo.fromElectrumBundle(
      ElectrumTransactionBundle(tx, ins: [null], confirmations: 10),
      walletType,
      network,
      addresses: {walletAddress},
    );
  }

  group("coinbase payouts", () {
    test("are settled as an incoming payment without a parent fetch", () {
      final info = coinbasePayout();

      expect(info.isCoinbase, isTrue);
      expect(info.needsResolution, isFalse);
      expect(info.isAmountPending, isFalse);
      expect(info.direction, TransactionDirection.incoming);
      expect(info.amount.amount, BigInt.from(payout));
    });

    test("keep no fee, since there is none to compute", () {
      expect(coinbasePayout().fee, isNull);
    });
  });

  group("history saved before the ownership flags existed", () {
    Map<String, dynamic> legacyJson(ElectrumTransactionInfo info, {required bool withFee}) {
      final json = Map<String, dynamic>.of(info.toJson());
      json.remove("inputsOwnershipFullyResolved");
      json.remove("isWalletDisplayAmountExact");
      json.remove("isCoinbase");
      if (!withFee) {
        json["fee"] = null;
      }
      return json;
    }

    test("a record that has a fee loads as settled, not pending", () {
      final json = legacyJson(coinbasePayout(), withFee: true);
      json["fee"] = 100;

      final info = ElectrumTransactionInfo.fromJson(json, walletType);

      expect(info.inputsOwnershipFullyResolved, isTrue);
      expect(info.isAmountPending, isFalse);
    });

    test("a record without a fee is queued for resolution, so it settles on the next pass", () {
      final json = legacyJson(coinbasePayout(), withFee: false);

      final info = ElectrumTransactionInfo.fromJson(json, walletType);

      expect(info.inputsOwnershipFullyResolved, isFalse);
      expect(info.needsResolution, isTrue);
    });
  });
}
