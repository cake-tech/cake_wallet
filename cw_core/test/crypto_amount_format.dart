import 'package:flutter_test/flutter_test.dart';
import 'package:cw_core/crypto_amount_format.dart';

void main() {
  group('String.withMaxDecimals', () {
    test('should return the original string when it has fewer decimal places than the max', () {
      final input = '123.45';
      final result = input.withMaxDecimals(3);
      
      expect(result, equals(input));
    });

    test('should truncate decimal places when the string has more than the max', () {
      final input = '123.4567';
      final result = input.withMaxDecimals(2);
      
      expect(result, equals('123.45'));
    });

    test('should handle strings with no decimal places', () {
      final input = '123';
      final result = input.withMaxDecimals(2);
      
      expect(result, equals(input));
    });

    test('should handle strings with multiple decimal points', () {
      final input = '123.45.67';
      final result = input.withMaxDecimals(4);
      
      expect(result, equals('123.4567'));
    });
  });
}
