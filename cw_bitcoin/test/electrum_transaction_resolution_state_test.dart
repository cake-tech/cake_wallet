import "package:bitcoin_base/bitcoin_base.dart";
import "package:cw_bitcoin/electrum_transaction_info.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";

// The definitions isAmountPending and needsResolution had before
// TransactionResolutionState existed, copied here to check the new getters against.
bool oldIsAmountPending(ElectrumTransactionInfo info) {
  final ownershipResolved = info.inputsOwnershipFullyResolved;
  if (ownershipResolved == true) {
    return false;
  }

  final isWalletDisplayAmountExact = info.additionalInfo["isWalletDisplayAmountExact"] as bool?;
  if (isWalletDisplayAmountExact != null) {
    return !isWalletDisplayAmountExact;
  }

  return ownershipResolved == false;
}

bool oldNeedsResolution(ElectrumTransactionInfo info) =>
    !info.inputsOwnershipFullyResolved || (info.fee == null && !info.isCoinbase);

void expectMatchesOldDefinitions(
  ElectrumTransactionInfo info,
  TransactionResolutionState expected,
) {
  expect(info.resolutionState, expected, reason: "resolutionState");
  expect(info.isAmountPending, oldIsAmountPending(info), reason: "isAmountPending");
  expect(info.needsResolution, oldNeedsResolution(info), reason: "needsResolution");
  expect(info.isAmountPending, expected == TransactionResolutionState.pending);
  expect(info.needsResolution, expected != TransactionResolutionState.settled);
}

void main() {
  const network = BitcoinNetwork.mainnet;
  const walletType = WalletType.bitcoin;

  final ours = ECPrivate.random().getPublic();
  final stranger = ECPrivate.random().getPublic();
  final ourAddress = ours.toP2wpkhAddress().toAddress(network);
  final placeholderSig = "11" * 64;

  // A parent transaction paying [key], so an input spending it can be resolved.
  BtcTransaction parentPaying(ECPublic key, int amount) => BtcTransaction(
        inputs: [],
        outputs: [
          TxOutput(
            amount: BigInt.from(amount),
            scriptPubKey: key.toP2wpkhAddress().toScriptPubKey(),
          ),
        ],
        hasSegwit: false,
      );

  ElectrumTransactionInfo fromBundle(BtcTransaction tx, List<BtcTransaction?> ins) =>
      ElectrumTransactionInfo.fromElectrumBundle(
        ElectrumTransactionBundle(tx, ins: ins, confirmations: 3),
        walletType,
        network,
        addresses: {ourAddress},
      );

  // A bare 64-byte signature in the witness (P2TR key-path) says nothing about
  // whose key signed it, so the input's ownership can't be told without its parent.
  BtcTransaction taprootKeyPathSpend() => BtcTransaction(
        inputs: [TxInput(txId: "aa" * 32, txIndex: 0)],
        outputs: [
          TxOutput(
            amount: BigInt.from(30000),
            scriptPubKey: stranger.toP2wpkhAddress().toScriptPubKey(),
          ),
          TxOutput(
            amount: BigInt.from(19000),
            scriptPubKey: ours.toP2wpkhAddress().toScriptPubKey(),
          ),
        ],
        witnesses: [
          TxWitnessInput(stack: [placeholderSig]),
        ],
        hasSegwit: true,
      );

  // A receive from a foreign input whose pubkey shows it isn't ours, without its parent.
  BtcTransaction receiveFromKnownForeignInput() => BtcTransaction(
        inputs: [TxInput(txId: "bb" * 32, txIndex: 0)],
        outputs: [
          TxOutput(
            amount: BigInt.from(19000),
            scriptPubKey: ours.toP2wpkhAddress().toScriptPubKey(),
          ),
        ],
        witnesses: [
          TxWitnessInput(stack: [placeholderSig, stranger.toHex()]),
        ],
        hasSegwit: true,
      );

  // Spends one of ours (parent fetched) plus a foreign input whose parent is not
  // fetched, so the amount is exact but the fee and that input are still open.
  ElectrumTransactionInfo ownedResolvedForeignOpen() => fromBundle(
        BtcTransaction(
          inputs: [
            TxInput(txId: "cc" * 32, txIndex: 0),
            TxInput(txId: "dd" * 32, txIndex: 0),
          ],
          outputs: [
            TxOutput(
              amount: BigInt.from(30000),
              scriptPubKey: stranger.toP2wpkhAddress().toScriptPubKey(),
            ),
            TxOutput(
              amount: BigInt.from(19000),
              scriptPubKey: ours.toP2wpkhAddress().toScriptPubKey(),
            ),
          ],
          witnesses: [
            TxWitnessInput(stack: []),
            TxWitnessInput(stack: [placeholderSig, stranger.toHex()]),
          ],
          hasSegwit: true,
        ),
        [parentPaying(ours, 50000), null],
      );

  final strangerParent = parentPaying(stranger, 50000);
  ElectrumTransactionInfo settledReceive() => fromBundle(
        BtcTransaction(
          inputs: [TxInput(txId: strangerParent.txId(), txIndex: 0)],
          outputs: [
            TxOutput(
              amount: BigInt.from(40000),
              scriptPubKey: ours.toP2wpkhAddress().toScriptPubKey(),
            ),
          ],
          hasSegwit: false,
        ),
        [strangerParent],
      );

  ElectrumTransactionInfo coinbasePayout() {
    const payout = 1500000;
    final tx = BtcTransaction(
      inputs: [TxInput(txId: "00" * 32, txIndex: 0xffffffff)],
      outputs: [
        TxOutput(
          amount: BigInt.from(payout),
          scriptPubKey: ours.toP2wpkhAddress().toScriptPubKey(),
        ),
      ],
      hasSegwit: false,
    );

    return fromBundle(tx, [null]);
  }

  // Shaped like a Lightning payment: ownership is always resolved for these,
  // whatever the stored flags say.
  ElectrumTransactionInfo lightningPayment({Money? fee}) => ElectrumTransactionInfo(
        walletType,
        id: "lightning",
        amount: Money.fromInt(1000, CryptoCurrency.btcln),
        fee: fee,
        direction: TransactionDirection.outgoing,
        isPending: false,
        date: DateTime.utc(2024, 6, 15),
        confirmations: 0,
        inputsOwnershipFullyResolved: false,
        additionalInfo: {"isLightning": true, "isWalletDisplayAmountExact": false},
      );

  // Shaped like a Silent Payment receive as electrum_wallet.dart builds it.
  ElectrumTransactionInfo silentPaymentReceive({required Money? fee}) => ElectrumTransactionInfo(
        walletType,
        id: "silent_payment",
        amount: Money.fromInt(1000, CryptoCurrency.btc),
        fee: fee,
        direction: TransactionDirection.incoming,
        isPending: false,
        date: DateTime.utc(2024, 6, 15),
        confirmations: 2,
        isReceivedSilentPayment: true,
        unspents: [],
      );

  // A history record from before the ownership flags existed, with the flags stripped.
  Map<String, dynamic> legacyJson({required bool withFee}) {
    final json = Map<String, dynamic>.of(settledReceive().toJson());
    json.remove("inputsOwnershipFullyResolved");
    final additionalInfo = Map<String, dynamic>.of(json["additionalInfo"] as Map<String, dynamic>)
      ..remove("isWalletDisplayAmountExact")
      ..remove("isCoinbase");
    json["additionalInfo"] = additionalInfo;
    if (!withFee) {
      json["fee"] = null;
    }
    return json;
  }

  group("resolutionState", () {
    test("settled receive with its fee is settled", () {
      final info = settledReceive();

      expect(info.fee, isNotNull);
      expectMatchesOldDefinitions(info, TransactionResolutionState.settled);
    });

    test("amount final but fee null is amountFinal", () {
      final info = fromBundle(receiveFromKnownForeignInput(), [null]);

      expect(info.fee, isNull);
      expect(info.inputsOwnershipFullyResolved, isTrue);
      expect(info.additionalInfo["isWalletDisplayAmountExact"], isTrue);
      expectMatchesOldDefinitions(info, TransactionResolutionState.amountFinal);
    });

    test("owned inputs resolved while a foreign input is still open is amountFinal", () {
      final info = ownedResolvedForeignOpen();

      expect(info.inputsOwnershipFullyResolved, isFalse);
      expect(info.additionalInfo["isWalletDisplayAmountExact"], isTrue);
      expectMatchesOldDefinitions(info, TransactionResolutionState.amountFinal);
    });

    test("unresolved owned input (P2TR key-path) is pending", () {
      final info = fromBundle(taprootKeyPathSpend(), [null]);

      expect(info.isAmountPending, isTrue);
      expectMatchesOldDefinitions(info, TransactionResolutionState.pending);
    });

    test("coinbase payout with no fee is settled", () {
      final info = coinbasePayout();

      expect(info.isCoinbase, isTrue);
      expect(info.fee, isNull);
      expectMatchesOldDefinitions(info, TransactionResolutionState.settled);
    });

    test("legacy record with a fee is settled", () {
      final info = ElectrumTransactionInfo.fromJson(legacyJson(withFee: true), walletType);

      expect(info.inputsOwnershipFullyResolved, isTrue);
      expectMatchesOldDefinitions(info, TransactionResolutionState.settled);
    });

    test("legacy record without a fee is pending, as it was before", () {
      final info = ElectrumTransactionInfo.fromJson(legacyJson(withFee: false), walletType);

      expect(info.inputsOwnershipFullyResolved, isFalse);
      expect(info.additionalInfo.containsKey("isWalletDisplayAmountExact"), isFalse);
      expectMatchesOldDefinitions(info, TransactionResolutionState.pending);
    });

    test("Lightning with a fee is settled, even with stored pending flags", () {
      final info = lightningPayment(fee: Money.fromInt(10, CryptoCurrency.btcln));

      expect(info.inputsOwnershipFullyResolved, isTrue);
      expectMatchesOldDefinitions(info, TransactionResolutionState.settled);
    });

    test("Lightning without a fee is amountFinal, not pending", () {
      final info = lightningPayment(fee: null);

      expect(info.isAmountPending, isFalse);
      expectMatchesOldDefinitions(info, TransactionResolutionState.amountFinal);
    });

    test("Silent Payment receive with its zero fee is settled", () {
      final info = silentPaymentReceive(fee: Money.zero(CryptoCurrency.btc));

      expectMatchesOldDefinitions(info, TransactionResolutionState.settled);
    });

    test("Silent Payment receive without a fee is amountFinal", () {
      final info = silentPaymentReceive(fee: null);

      expectMatchesOldDefinitions(info, TransactionResolutionState.amountFinal);
    });

    test("ownership unresolved with no amount flag is pending", () {
      final info = ElectrumTransactionInfo(
        walletType,
        id: "unresolved",
        amount: Money.fromInt(1, CryptoCurrency.btc),
        fee: Money.fromInt(10, CryptoCurrency.btc),
        direction: TransactionDirection.incoming,
        isPending: false,
        date: DateTime.utc(2024, 6, 15),
        confirmations: 1,
        inputsOwnershipFullyResolved: false,
      );

      expectMatchesOldDefinitions(info, TransactionResolutionState.pending);
    });
  });

  test("every combination of the stored flags agrees with the old definitions", () {
    var checked = 0;

    for (final ownership in [true, false]) {
      for (final exact in <bool?>[null, true, false]) {
        for (final feeKnown in [true, false]) {
          for (final coinbase in [false, true]) {
            for (final lightning in [false, true]) {
              for (final silentPayment in [false, true]) {
                final info = ElectrumTransactionInfo(
                  walletType,
                  id: "grid",
                  amount: Money.fromInt(1, CryptoCurrency.btc),
                  fee: feeKnown ? Money.fromInt(10, CryptoCurrency.btc) : null,
                  direction: TransactionDirection.incoming,
                  isPending: false,
                  date: DateTime.utc(2024, 6, 15),
                  confirmations: 1,
                  isReceivedSilentPayment: silentPayment,
                  inputsOwnershipFullyResolved: ownership,
                  additionalInfo: {
                    if (exact != null) "isWalletDisplayAmountExact": exact,
                    if (coinbase) "isCoinbase": true,
                    if (lightning) "isLightning": true,
                  },
                );
                final label = "ownership=$ownership exact=$exact fee=$feeKnown "
                    "coinbase=$coinbase lightning=$lightning silentPayment=$silentPayment";

                expect(info.isAmountPending, oldIsAmountPending(info), reason: label);
                expect(info.needsResolution, oldNeedsResolution(info), reason: label);
                expect(
                  info.isAmountPending,
                  info.resolutionState == TransactionResolutionState.pending,
                  reason: label,
                );
                expect(
                  info.needsResolution,
                  info.resolutionState != TransactionResolutionState.settled,
                  reason: label,
                );
                checked++;
              }
            }
          }
        }
      }
    }

    expect(checked, 96);
  });
}
