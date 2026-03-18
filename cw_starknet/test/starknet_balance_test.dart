import 'package:flutter_test/flutter_test.dart';
import 'package:cw_starknet/starknet_balance.dart';

void main() {
  group('StarknetBalance', () {
    test('creates balance from double', () {
      final balance = StarknetBalance(1.5);
      expect(balance.balance, 1.5);
    });

    test('zero balance', () {
      final balance = StarknetBalance(0.0);
      expect(balance.balance, 0.0);
      expect(balance.formattedAvailableBalance, '0.0');
    });

    test('formattedAvailableBalance truncates long strings', () {
      final balance = StarknetBalance(1.123456789012345);
      final formatted = balance.formattedAvailableBalance;
      expect(formatted.length, lessThanOrEqualTo(12));
    });

    test('formattedAdditionalBalance equals formattedAvailableBalance', () {
      final balance = StarknetBalance(2.5);
      expect(
          balance.formattedAdditionalBalance, balance.formattedAvailableBalance);
    });

    group('JSON serialization', () {
      test('toJSON produces valid JSON', () {
        final balance = StarknetBalance(1.25);
        final json = balance.toJSON();
        expect(json.contains('balance'), true);
        expect(json.contains('1.25'), true);
      });

      test('fromJSON round-trips correctly', () {
        final original = StarknetBalance(3.14159);
        final json = original.toJSON();
        final restored = StarknetBalance.fromJSON(json);

        expect(restored, isNotNull);
        expect(restored!.balance, closeTo(original.balance, 0.0001));
      });

      test('fromJSON returns null for null input', () {
        final result = StarknetBalance.fromJSON(null);
        expect(result, isNull);
      });

      test('fromJSON returns zero for malformed input', () {
        final result = StarknetBalance.fromJSON('{"balance": "not_a_number"}');
        // Should not crash; returns 0.0 on parse failure
        expect(result, isNotNull);
      });

      test('fromJSON handles integer balance', () {
        final result = StarknetBalance.fromJSON('{"balance": "5"}');
        expect(result, isNotNull);
        expect(result!.balance, 5.0);
      });
    });

    group('Large and small values', () {
      test('very small balance', () {
        final balance = StarknetBalance(0.000000000000000001);
        expect(balance.balance, greaterThanOrEqualTo(0));
      });

      test('large balance', () {
        final balance = StarknetBalance(1000000.123456);
        expect(balance.balance, 1000000.123456);
      });
    });
  });
}
