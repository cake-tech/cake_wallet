import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_info.dart";
import "package:flutter_test/flutter_test.dart";

class _FlaggedTransactionInfo extends TransactionInfo {
  _FlaggedTransactionInfo({this.ownership, Map<String, dynamic> flags = const {}}) {
    id = "flagged";
    amount = Money.fromInt(0, CryptoCurrency.btc);
    direction = TransactionDirection.incoming;
    isPending = false;
    date = DateTime.utc(2024, 6, 15);
    additionalInfo = Map<String, dynamic>.of(flags);
  }

  final bool? ownership;

  @override
  bool? get inputsOwnershipFullyResolved => ownership;
}

// The isAmountPending definition from before TransactionResolutionState existed.
bool oldIsAmountPending(TransactionInfo info) {
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

void main() {
  group("TransactionInfo.resolutionState", () {
    test("a wallet without ownership tracking with no flags is settled", () {
      final info = _FlaggedTransactionInfo();

      expect(info.resolutionState, TransactionResolutionState.settled);
      expect(info.isAmountPending, isFalse);
    });

    test("a wallet that never sets the flags is never amountFinal", () {
      for (final ownership in <bool?>[null, true, false]) {
        for (final exact in <bool?>[null, true, false]) {
          final info = _FlaggedTransactionInfo(
            ownership: ownership,
            flags: {"isWalletDisplayAmountExact": ?exact},
          );
          final label = "ownership=$ownership exact=$exact";

          expect(
            info.resolutionState == TransactionResolutionState.amountFinal,
            isFalse,
            reason: label,
          );
          expect(info.isAmountPending, oldIsAmountPending(info), reason: label);
          expect(
            info.isAmountPending,
            info.resolutionState == TransactionResolutionState.pending,
            reason: label,
          );
        }
      }
    });

    test("an amount flagged not exact is pending, unless ownership is resolved", () {
      expect(
        _FlaggedTransactionInfo(flags: {"isWalletDisplayAmountExact": false}).resolutionState,
        TransactionResolutionState.pending,
      );
      expect(
        _FlaggedTransactionInfo(
          ownership: true,
          flags: {"isWalletDisplayAmountExact": false},
        ).resolutionState,
        TransactionResolutionState.settled,
      );
    });

    test("history saved before the amount flag existed is pending when ownership is open", () {
      expect(
        _FlaggedTransactionInfo(ownership: false).resolutionState,
        TransactionResolutionState.pending,
      );
    });
  });
}
