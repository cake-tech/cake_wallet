import 'package:cake_wallet/view_model/transaction_details_view_model.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PIVX shielded transaction detail formatting', () {
    test('labels pending receive with confirmation progress', () {
      final tx = _FakeTransactionInfo(
        direction: TransactionDirection.incoming,
        confirmations: 2,
        isPending: true,
      );

      expect(
        TransactionDetailsViewModelBase.pivxShieldedConfirmationState(tx, 6),
        'Pending shielded receive (2/6)',
      );
    });

    test('labels confirmed receive as spendable', () {
      final tx = _FakeTransactionInfo(
        direction: TransactionDirection.incoming,
        confirmations: 6,
        isPending: false,
      );

      expect(
        TransactionDetailsViewModelBase.pivxShieldedConfirmationState(tx, 6),
        'Spendable shielded receive',
      );
    });

    test('labels pending outgoing broadcast before mined spend', () {
      final tx = _FakeTransactionInfo(
        direction: TransactionDirection.outgoing,
        confirmations: 0,
        isPending: true,
      );

      expect(
        TransactionDetailsViewModelBase.pivxShieldedConfirmationState(tx, 6),
        'Broadcast, waiting for mined shielded spend (0/6)',
      );
    });

    test('labels mined outgoing shielded send before required confirmations', () {
      final tx = _FakeTransactionInfo(
        direction: TransactionDirection.outgoing,
        confirmations: 3,
        isPending: false,
      );

      expect(
        TransactionDetailsViewModelBase.pivxShieldedConfirmationState(tx, 6),
        'Pending shielded send (3/6)',
      );
    });

    test('labels confirmed outgoing shielded send', () {
      final tx = _FakeTransactionInfo(
        direction: TransactionDirection.outgoing,
        confirmations: 7,
        isPending: false,
      );

      expect(
        TransactionDetailsViewModelBase.pivxShieldedConfirmationState(tx, 6),
        'Confirmed shielded send',
      );
    });

    test('clamps negative confirmation progress to zero', () {
      final tx = _FakeTransactionInfo(
        direction: TransactionDirection.incoming,
        confirmations: -3,
        isPending: true,
      );

      expect(
        TransactionDetailsViewModelBase.pivxShieldedConfirmationState(tx, 6),
        'Pending shielded receive (0/6)',
      );
    });

    test('formats PIVX pools and routes for details rows', () {
      expect(TransactionDetailsViewModelBase.formatPivxPool('shielded'),
          'Shielded');
      expect(TransactionDetailsViewModelBase.formatPivxPool('transparent'),
          'Transparent');
      expect(TransactionDetailsViewModelBase.formatPivxRoute('z-receive'),
          'Shielded receive');
      expect(TransactionDetailsViewModelBase.formatPivxRoute('z-to-z'),
          'Shielded to shielded');
      expect(TransactionDetailsViewModelBase.formatPivxRoute('t-to-t'),
          'Transparent to transparent');
      expect(TransactionDetailsViewModelBase.formatPivxRoute('t-to-z'),
          'Shielding');
      expect(TransactionDetailsViewModelBase.formatPivxRoute('z-to-t'),
          'Deshielding');
    });
  });
}

class _FakeTransactionInfo extends TransactionInfo {
  _FakeTransactionInfo({
    required TransactionDirection direction,
    required int confirmations,
    required bool isPending,
  }) {
    id = 'pivx-shielded-tx';
    txHash = id;
    amount = 123;
    fee = 1;
    this.direction = direction;
    this.confirmations = confirmations;
    this.isPending = isPending;
    date = DateTime.fromMillisecondsSinceEpoch(0);
    height = confirmations > 0 ? 100 : 0;
  }

  @override
  String amountFormatted() => '0.00000123 PIVX';

  @override
  void changeFiatAmount(String amount) {}

  @override
  String feeFormatted() => '0.00000001 PIVX';

  @override
  String fiatAmount() => '0.00';
}
