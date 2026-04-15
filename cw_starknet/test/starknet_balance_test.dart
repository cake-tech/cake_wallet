import 'package:flutter_test/flutter_test.dart';
import 'package:cw_starknet/starknet_balance.dart';

void main() {
  group('StarknetBalance', () {
    test('creates balance from raw units', () {
      final balance = StarknetBalance(BigInt.from(1500), decimals: 3);
      expect(balance.balance, 1.5);
    });

    test('zero balance', () {
      final balance = StarknetBalance.zero();
      expect(balance.balance, 0.0);
      expect(balance.formattedAvailableBalance, '0');
    });

    test('formattedAvailableBalance truncates long strings', () {
      final balance = StarknetBalance(
        BigInt.parse('1123456789012345678'),
        decimals: 18,
      );
      final formatted = balance.formattedAvailableBalance;
      expect(formatted.length, lessThanOrEqualTo(12));
    });

    test('formattedAdditionalBalance equals formattedAvailableBalance', () {
      final balance = StarknetBalance(BigInt.from(2500), decimals: 3);
      expect(balance.formattedAdditionalBalance,
          balance.formattedAvailableBalance);
    });

    group('JSON serialization', () {
      test('toJSON produces valid JSON', () {
        final balance = StarknetBalance(BigInt.from(1250), decimals: 3);
        final json = balance.toJSON();
        expect(json.contains('raw_balance'), true);
        expect(json.contains('1250'), true);
      });

      test('fromJSON round-trips correctly', () {
        final original = StarknetBalance(BigInt.parse('314159'), decimals: 5);
        final json = original.toJSON();
        final restored = StarknetBalance.fromJSON(json);

        expect(restored, isNotNull);
        expect(restored!.balance, closeTo(original.balance, 0.0001));
        expect(restored.rawBalance, original.rawBalance);
        expect(restored.decimals, original.decimals);
      });

      test('fromJSON returns null for null input', () {
        final result = StarknetBalance.fromJSON(null);
        expect(result, isNull);
      });

      test('fromJSON returns zero for malformed input', () {
        final result = StarknetBalance.fromJSON('{"raw_balance": "not_a_number"}');
        // Should not crash; returns 0.0 on parse failure
        expect(result, isNotNull);
        expect(result!.rawBalance, BigInt.zero);
      });

      test('fromJSON handles integer balance', () {
        final result = StarknetBalance.fromJSON('{"raw_balance": "5", "decimals": 0}');
        expect(result, isNotNull);
        expect(result!.balance, 5.0);
      });
    });

    group('Large and small values', () {
      test('very small balance', () {
        final balance = StarknetBalance(BigInt.one, decimals: 18);
        expect(balance.balance, greaterThanOrEqualTo(0));
      });

      test('large balance', () {
        final balance = StarknetBalance(BigInt.parse('1000000123456'), decimals: 6);
        expect(balance.formattedAvailableBalance, '1000000.1234');
        expect(balance.balance, 1000000.1234);
      });
    });
  });
}
