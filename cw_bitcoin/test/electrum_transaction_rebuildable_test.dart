import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_transaction_resolver.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// A rebuild classifies a transaction against the Electrum address set. Records
/// whose amount or ownership comes from somewhere else must never be rebuilt,
/// or the rebuild overwrites them with values the address set can't produce.
void main() {
  final currency = walletTypeToCryptoCurrency(WalletType.bitcoin);
  final base = DateTime(2024, 1, 1);
  const walletAddress = "bc1qwalletaddress";
  const spOutputAddress = "bc1pspoutput";

  ElectrumTransactionInfo tx(
    String id, {
    bool isReceivedSilentPayment = false,
    Map<String, dynamic>? additionalInfo,
    List<String>? outputAddresses,
    bool inputsResolved = true,
    bool hasFee = true,
  }) =>
      ElectrumTransactionInfo(
        WalletType.bitcoin,
        id: id,
        amount: Money.fromInt(50000, currency),
        fee: hasFee ? Money.zero(currency) : null,
        direction: TransactionDirection.incoming,
        isPending: false,
        date: base,
        confirmations: 10,
        outputAddresses: outputAddresses ?? [walletAddress],
        isReceivedSilentPayment: isReceivedSilentPayment,
        inputsOwnershipFullyResolved: inputsResolved,
        additionalInfo: additionalInfo,
      );

  group("ElectrumTransactionResolver.isRebuildable", () {
    test("an ordinary wallet transaction can be rebuilt", () {
      expect(ElectrumTransactionResolver.isRebuildable(tx("ordinary")), isTrue);
    });

    test("a scanned Silent Payment receive can't, its output is outside the address set", () {
      final sp = tx(
        "sp",
        isReceivedSilentPayment: true,
        outputAddresses: [spOutputAddress],
        inputsResolved: false,
      );

      expect(ElectrumTransactionResolver.isRebuildable(sp), isFalse);
    });

    test("a Lightning record can't, its id is not an on-chain txid", () {
      final ln = tx("ln", additionalInfo: {"isLightning": true});

      expect(ElectrumTransactionResolver.isRebuildable(ln), isFalse);
    });

    test("a Spark deposit can't, even though it carries a real txid", () {
      final spark = tx(
        "spark",
        additionalInfo: {"isLightning": true, "isSparkDeposit": true},
      );

      expect(ElectrumTransactionResolver.isRebuildable(spark), isFalse);
    });

    test("a Litecoin MWEB record can't, it lists its own output id as its output", () {
      const outputId = "mwebOutputId";
      final mweb = tx(outputId, outputAddresses: [outputId]);

      expect(ElectrumTransactionResolver.isRebuildable(mweb), isFalse);
    });
  });

  group("ElectrumTransactionResolver.needsAddressRecheck", () {
    test("never asks for a recheck of a Silent Payment receive, even with the legacy heuristic",
        () {
      // Legacy shape: no address set size recorded, resolved, no owned inputs.
      final sp = tx(
        "sp",
        isReceivedSilentPayment: true,
        outputAddresses: [spOutputAddress],
        additionalInfo: {"ownedInputs": <Map<String, dynamic>>[]},
      );

      expect(
        ElectrumTransactionResolver.needsAddressRecheck(sp, {walletAddress, spOutputAddress}),
        isFalse,
      );
    });

    test("never asks for a recheck of a Lightning record", () {
      final ln = tx("ln", additionalInfo: {"isLightning": true});

      expect(ElectrumTransactionResolver.needsAddressRecheck(ln, {walletAddress}), isFalse);
    });

    test("still asks for a recheck of an ordinary transaction whose address set grew", () {
      final ordinary = tx("ordinary", additionalInfo: {"addressSetSizeKey": 1});

      expect(
        ElectrumTransactionResolver.needsAddressRecheck(ordinary, {walletAddress, "bc1qnew"}),
        isTrue,
      );
    });
  });

  group("ElectrumTransactionResolver.buildPendingQueue", () {
    test("leaves out records that can't be rebuilt, even when they need resolution", () {
      final queue = ElectrumTransactionResolver.buildPendingQueue([
        tx("ordinary", inputsResolved: false, hasFee: false),
        tx(
          "sp",
          isReceivedSilentPayment: true,
          outputAddresses: [spOutputAddress],
          inputsResolved: false,
          hasFee: false,
        ),
        tx("mweb", outputAddresses: ["mweb"], inputsResolved: false, hasFee: false),
      ]);

      expect(queue, ["ordinary"]);
    });
  });
}
