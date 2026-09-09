import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/transaction_info.dart";
import "package:flutter_test/flutter_test.dart";

class _Tx extends TransactionInfo {
  _Tx({required TransactionDirection direction, required bool isPending})
      : super(
          id: "a",
          amount: Money.fromInt(1, CryptoCurrency.btc),
          direction: direction,
          date: DateTime(2026, 1, 1),
        ) {
    this.isPending = isPending;
  }
}

class _ShieldingTx extends _Tx {
  _ShieldingTx({
    required super.isPending,
    this.shielding = false,
    this.migration = false,
  }) : super(direction: TransactionDirection.incoming);

  final bool shielding;
  final bool migration;

  @override
  String get title {
    if (migration) {
      return "transaction_migration";
    }
    if (shielding) {
      return "shielding";
    }
    return super.title;
  }

  @override
  bool get hasStatus => migration ? false : super.hasStatus;
}

void main() {
  group("TransactionInfo.title", () {
    test("settled transactions are received or sent, with no status", () {
      final incoming = _Tx(direction: TransactionDirection.incoming, isPending: false);
      expect(incoming.title, "received");
      expect(incoming.hasStatus, isFalse);

      final outgoing = _Tx(direction: TransactionDirection.outgoing, isPending: false);
      expect(outgoing.title, "sent");
      expect(outgoing.hasStatus, isFalse);
    });

    test("in-flight transactions are receiving or sending, and carry status", () {
      final incoming = _Tx(direction: TransactionDirection.incoming, isPending: true);
      expect(incoming.title, "receiving");
      expect(incoming.hasStatus, isTrue);

      final outgoing = _Tx(direction: TransactionDirection.outgoing, isPending: true);
      expect(outgoing.title, "sending");
      expect(outgoing.hasStatus, isTrue);
    });

    test("a subclass state wins over the shared one", () {
      expect(_ShieldingTx(isPending: false, shielding: true).title, "shielding");
      expect(_ShieldingTx(isPending: false, migration: true).title, "transaction_migration");
    });

    test("a subclass state still reports status only while in flight", () {
      expect(_ShieldingTx(isPending: true, shielding: true).hasStatus, isTrue);
      expect(_ShieldingTx(isPending: false, shielding: true).hasStatus, isFalse);
    });

    test("a state can suppress status even while in flight", () {
      // A migration in flight still reads plainly, as it did before the move.
      expect(_ShieldingTx(isPending: true, migration: true).hasStatus, isFalse);
    });

    test("a subclass falls back to the shared logic when its state doesn't apply", () {
      expect(_ShieldingTx(isPending: false).title, "received");

      final inFlight = _ShieldingTx(isPending: true);
      expect(inFlight.title, "receiving");
      expect(inFlight.hasStatus, isTrue);
    });
  });
}
