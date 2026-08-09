import 'package:cw_monero/api/transaction_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('hasMultipleDestinationsWithIntegratedPaymentId', () {
    // Stand-in for the native Monero address parse (Wallet_paymentIdFromAddress):
    // any address prefixed with "integrated:" decodes to an integrated address
    // carrying an embedded payment ID.
    bool isIntegrated(String address) => address.startsWith('integrated:');

    test('rejects multiple destinations when at least one carries an integrated payment ID', () {
      expect(
        hasMultipleDestinationsWithIntegratedPaymentId(
            ['4AdDr3551111', 'integrated:9mGe8A'], isIntegrated),
        isTrue,
      );
    });

    test('allows a single integrated destination', () {
      expect(
        hasMultipleDestinationsWithIntegratedPaymentId(['integrated:9mGe8A'], isIntegrated),
        isFalse,
      );
    });

    test('allows multiple ordinary destinations', () {
      expect(
        hasMultipleDestinationsWithIntegratedPaymentId(
            ['4AdDr3551', '4AdDr3552', '4AdDr3553'], isIntegrated),
        isFalse,
      );
    });

    test('counts only non-empty destinations', () {
      // A single non-empty destination is never rejected, even when it is integrated.
      expect(
        hasMultipleDestinationsWithIntegratedPaymentId(['', 'integrated:9mGe8A'], isIntegrated),
        isFalse,
      );
      // ... but the integrated destination is still detected among several non-empty ones.
      expect(
        hasMultipleDestinationsWithIntegratedPaymentId(
            ['', '4AdDr3551', 'integrated:9mGe8A'], isIntegrated),
        isTrue,
      );
    });
  });
}
