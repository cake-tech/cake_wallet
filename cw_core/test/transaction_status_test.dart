import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_info.dart";
import "package:flutter_test/flutter_test.dart";

class _Tx extends TransactionInfo {
  _Tx({int confirmations = 0, Map<String, dynamic>? extra})
      : super(
          id: "a",
          amount: Money.fromInt(1, CryptoCurrency.btc),
          direction: TransactionDirection.incoming,
          date: DateTime(2026, 1, 1),
        ) {
    isPending = true;
    this.confirmations = confirmations;
    if (extra != null) {
      additionalInfo = extra;
    }
  }
}

/// A chain that just needs N confirmations, like monero and zano.
/// A transaction denominated in something other than the wallet's own coin.
class _TokenTx extends TransactionInfo {
  _TokenTx(CryptoCurrency token)
      : super(
          id: "t",
          amount: Money.fromInt(1, token),
          direction: TransactionDirection.incoming,
          date: DateTime(2026, 1, 1),
        ) {
    isPending = false;
  }
}

class _CountingTx extends _Tx {
  _CountingTx({required super.confirmations, required this.needed});

  final int needed;

  @override
  int get neededConfirmations => needed;
}

/// Mirrors the litecoin peg-out threshold on ElectrumTransactionInfo.
class _PegTx extends _Tx {
  _PegTx({required super.confirmations, super.extra});

  bool get _isPegOut => additionalInfo["isPegOut"] as bool? ?? false;
  bool get _fromPegOut => additionalInfo["fromPegOut"] as bool? ?? false;

  @override
  int get neededConfirmations => (_isPegOut || _fromPegOut) ? 6 : 0;
}

void main() {
  group("TransactionInfo.status", () {
    test("a chain needing no confirmations reports nothing", () {
      expect(_Tx(confirmations: 0).neededConfirmations, 0);
      expect(_Tx(confirmations: 0).status, isNull);
      expect(_Tx(confirmations: 99).status, isNull);
    });

    test("progress is reported while below the threshold", () {
      expect(_CountingTx(confirmations: 0, needed: 10).status, "(0/10)");
      expect(_CountingTx(confirmations: 3, needed: 10).status, "(3/10)");
      expect(_CountingTx(confirmations: 9, needed: 10).status, "(9/10)");
    });

    test("progress stops once the threshold is reached", () {
      expect(_CountingTx(confirmations: 10, needed: 10).status, isNull);
      expect(_CountingTx(confirmations: 40, needed: 10).status, isNull);
    });
  });

  group("litecoin peg threshold", () {
    test("a plain transaction has no threshold and no status", () {
      final tx = _PegTx(confirmations: 0);
      expect(tx.neededConfirmations, 0);
      expect(tx.status, isNull);
    });

    test("a peg-out in flight reports progress toward six", () {
      final tx = _PegTx(confirmations: 3, extra: {"isPegOut": true});
      expect(tx.neededConfirmations, 6);
      expect(tx.status, "(3/6)");
    });

    test("fromPegOut counts toward the threshold too", () {
      final tx = _PegTx(confirmations: 2, extra: {"fromPegOut": true});
      expect(tx.neededConfirmations, 6);
      expect(tx.status, "(2/6)");
    });

    test("a settled peg-out reports nothing", () {
      expect(_PegTx(confirmations: 10, extra: {"isPegOut": true}).status, isNull);
    });
  });

  group("TransactionInfo.assetOfTransaction", () {
    test("reads the currency the amount is denominated in", () {
      // No longer stamped by the wallet: whatever currency the amount was built
      // with *is* the asset.
      expect(_Tx().assetOfTransaction, CryptoCurrency.btc);
    });

    test("a token amount reports that token", () {
      final tx = _TokenTx(CryptoCurrency.usdcpoly);
      expect(tx.assetOfTransaction, CryptoCurrency.usdcpoly);
    });
  });
}
