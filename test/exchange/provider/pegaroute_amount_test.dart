import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_amount.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final decimals in [6, 8, 9, 12, 18]) {
    test('external $decimals-decimal amounts preserve one-base-unit differences', () {
      final quantum = '0.${'0' * (decimals - 1)}1';
      expect(pegarouteSameAmount(quantum, '${quantum}000'), isTrue);
      expect(pegarouteSameAmount(quantum, '0'), isFalse);
      expect(pegarouteSameAmount('1', '1.${'0' * decimals}'), isTrue);
      expect(pegarouteSameAmount('1', '1.${'0' * (decimals - 1)}1'), isFalse);
    });
  }

  test('large amounts compare exactly beyond floating-point precision', () {
    expect(pegarouteSameAmount('9007199254740993.1', '9007199254740993.100'), isTrue);
    expect(pegarouteSameAmount('9007199254740993.1', '9007199254740992.1'), isFalse);
    expect(pegarouteSameAmount('0.123456789', '0.12345678'), isFalse);
  });

  test('non-decimal external values cannot acquire amount identity', () {
    for (final invalid in ['NaN', 'Infinity', '-1', '+1', '1e0', '01', '1.', '.1', '']) {
      expect(pegarouteSameAmount(invalid, invalid), isFalse);
      expect(pegarouteSameAmount(invalid, '1'), isFalse);
    }
  });
}
