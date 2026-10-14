import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_bitcoin/electrum_transaction_resolver.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/currency_for_wallet_type.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// These tests matters for determinism: `List.sort` is not stable, so without
/// the id tiebreak, txs with equal flag and date could be processed in a
/// different order on every queue build. Their states change as they resolve
/// (amount, direction, fee), so an unstable order would make txs reshuffle and
/// jump around in the UI while resolving. A fixed order keeps each tx in place
/// as its state changes.
void main() {
  group('ElectrumTransactionResolver.buildPendingQueue', () {
    final base = DateTime(2024, 1, 1);

    ElectrumTransactionInfo tx(
      String id, {
      required bool inputsResolved,
      int daysOld = 0,
      bool hasFee = false,
    }) {
      final currency = walletTypeToCryptoCurrency(WalletType.bitcoin);

      return ElectrumTransactionInfo(
        WalletType.bitcoin,
        id: id,
        amount: Money.fromInt(1000, currency),
        fee: hasFee ? Money.fromInt(10, currency) : null,
        direction: TransactionDirection.incoming,
        isPending: false,
        date: base.subtract(Duration(days: daysOld)),
        confirmations: 1,
        additionalInfo: {'inputsOwnershipFullyResolved': inputsResolved},
      );
    }

    test('fully-resolved-inputs txs come before unresolved ones', () {
      final queue = ElectrumTransactionResolver.buildPendingQueue([
        tx('unresolved', inputsResolved: false, daysOld: 10),
        tx('resolved', inputsResolved: true, daysOld: 1),
      ]);

      expect(queue, ['resolved', 'unresolved']);
    });

    test('equal flags are ordered oldest first', () {
      final queue = ElectrumTransactionResolver.buildPendingQueue([
        tx('new', inputsResolved: true, daysOld: 1),
        tx('old', inputsResolved: true, daysOld: 30),
        tx('mid', inputsResolved: true, daysOld: 10),
      ]);

      expect(queue, ['old', 'mid', 'new']);

      final unresolved = ElectrumTransactionResolver.buildPendingQueue([
        tx('new', inputsResolved: false, daysOld: 1),
        tx('old', inputsResolved: false, daysOld: 30),
      ]);

      expect(unresolved, ['old', 'new']);
    });

    test('flag takes priority over date', () {
      final queue = ElectrumTransactionResolver.buildPendingQueue([
        tx('old-unresolved', inputsResolved: false, daysOld: 100),
        tx('new-resolved', inputsResolved: true, daysOld: 0),
        tx('old-resolved', inputsResolved: true, daysOld: 50),
        tx('new-unresolved', inputsResolved: false, daysOld: 0),
      ]);

      expect(queue, ['old-resolved', 'new-resolved', 'old-unresolved', 'new-unresolved']);
    });

    test('equal flag and date is deterministic regardless of input order', () {
      final a = tx('a', inputsResolved: true);
      final b = tx('b', inputsResolved: true);
      final c = tx('c', inputsResolved: true);
      expect(ElectrumTransactionResolver.buildPendingQueue([a, b, c]), ['a', 'b', 'c']);
      expect(ElectrumTransactionResolver.buildPendingQueue([c, b, a]), ['a', 'b', 'c']);
      expect(ElectrumTransactionResolver.buildPendingQueue([b, c, a]), ['a', 'b', 'c']);
    });

    test('txs that do not need resolution are excluded', () {
      final queue = ElectrumTransactionResolver.buildPendingQueue([
        tx('done', inputsResolved: true, hasFee: true),
        tx('needs-fee', inputsResolved: true),
      ]);

      expect(queue, ['needs-fee']);
    });
  });
}
