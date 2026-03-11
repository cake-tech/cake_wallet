import 'package:cw_core/crypto_amount_format.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('String.withLocalSeperator', () {
    group('Locale en_US', () {
      const locale = 'en_US';
      
      test('should not have a grouping separator', () {
        final input = '123.45';
        final result = input.withLocalSeperator(locale);

        expect(result, equals(input));
      });

      test('should have a grouping seperator', () {
        final input = '1123.4567';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('1,123.4567'));
      });

      test('should have multiple grouping seperator', () {
        final input = '1000000.4567';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('1,000,000.4567'));
      });
    });
    
    group('Locale de_DE', () {
      const locale = 'de_DE';
      
      test('should not have a grouping separator', () {
        final input = '123.45';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('123,45'));
      });

      test('should have a grouping seperator', () {
        final input = '1123.4567';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('1.123,4567'));
      });

      test('should have multiple grouping seperator', () {
        final input = '1000000.4567';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('1.000.000,4567'));
      });
    });

    group('Locale de_CH', () {
      const locale = 'de_CH';

      test('should not have a grouping separator', () {
        final input = '123.45';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('123.45'));
      });

      test('should have a grouping seperator', () {
        final input = '1123.4567';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('1’123.4567'));
      });

      test('should have multiple grouping seperator', () {
        final input = '1000000.4567';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('1’000’000.4567'));
      });
    });

    group('With XMR Suffix', () {
      const locale = 'de_CH';

      test('should handle suffix expected', () {
        final input = '1123.4567 XMR';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('1’123.4567 XMR'));
      });

      test('should handle suffix odd spacing', () {
        final input = '1123.4567  XMR ';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('1’123.4567  XMR '));
      });
    });

    group('With > < prefix', () {
      const locale = 'de_CH';

      test('should handle prefix and suffix', () {
        final input = '> 1123.4567 XMR';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('> 1’123.4567 XMR'));
      });

      test('should handle prefix and suffix odd spacing', () {
        final input = '< 1123.4567  XMR ';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('< 1’123.4567  XMR '));
      });

      test('should handle just prefix', () {
        final input = '< 1123.4567';
        final result = input.withLocalSeperator(locale);

        expect(result, equals('< 1’123.4567'));
      });
    });
  });
}
