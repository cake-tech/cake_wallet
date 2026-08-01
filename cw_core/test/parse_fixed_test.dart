import 'package:cw_core/parse_fixed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFixed', () {
    group('parseFixed, positive', () {
      test('should parse 1.000001 as 1000001',
          () => expect(parseFixed("1.000001", 6), BigInt.from(1000001)));

      test('should parse 1 as 1000000', () => expect(parseFixed("1", 6), BigInt.from(1000000)));

      test('should parse 1. as 1000000', () => expect(parseFixed("1.", 6), BigInt.from(1000000)));

      test('should parse 1.1 as 1100000', () => expect(parseFixed("1.1", 6), BigInt.from(1100000)));

      test('should parse 01.1 as 1100000',
          () => expect(parseFixed("01.1", 6), BigInt.from(1100000)));

      test('should parse 1100000 as 11000000',
          () => expect(parseFixed("1100000", 1), BigInt.from(11000000)));
    });

    group('parseFixed, negative', () {
      test('should parse -1.000001 as -1000001',
          () => expect(parseFixed("-1.000001", 6), BigInt.from(-1000001)));

      test('should parse -1 as 1000000', () => expect(parseFixed("-1", 6), BigInt.from(-1000000)));
    });

    group('parseFixed, no leading 0', () {
      test('should parse .000001 as 1', () => expect(parseFixed(".000001", 6), BigInt.from(1)));

      test('should parse .00002 as 20', () => expect(parseFixed(".00002", 6), BigInt.from(20)));

      test('should parse -.00002 as -20', () => expect(parseFixed("-.00002", 6), BigInt.from(-20)));
    });

    group('parseFixed, truncating excess precision', () {
      test('should keep an exact precision value unchanged',
          () => expect(parseFixed("1.123456", 6), BigInt.from(1123456)));

      test('should truncate one excess digit, not round up',
          () => expect(parseFixed("1.1234567", 6), BigInt.from(1123456)));

      test('should truncate one excess digit that would round up, not round up',
          () => expect(parseFixed("1.9999999", 6), BigInt.from(1999999)));

      test('should truncate many excess digits',
          () => expect(parseFixed("320.31402299", 6), BigInt.from(320314022)));

      test('should truncate trailing zero beyond the decimals, .0000010 as 1',
          () => expect(parseFixed(".0000010", 6), BigInt.from(1)));

      test('should truncate the magnitude of a negative value toward zero',
          () => expect(parseFixed("-1.9999999", 6), BigInt.from(-1999999)));

      test('should return 0 when the whole fractional part is below the precision',
          () => expect(parseFixed("0.0000001", 6), BigInt.zero));

      test('should return 0 when the whole fractional part of a negative is below the precision',
          () => expect(parseFixed("-0.0000001", 6), BigInt.zero));
    });

    group('parseFixed, failing', () {
      test('should fail to parse .000.0010, too many decimal points',
          () => expect(() => parseFixed(".000.0010", 6), throwsFormatException));

      test('should fail to parse `.`, missing value',
          () => expect(() => parseFixed(".", 6), throwsFormatException));

      test('should fail to parse a non numeric value',
          () => expect(() => parseFixed("1,11", 6), throwsFormatException));

      test('should fail to parse exponent notation',
          () => expect(() => parseFixed("1e5", 6), throwsFormatException));
    });
  });

  group('tryParseFixed', () {
    group('tryParseFixed, positive', () {
      test('should parse 1.000001 as 1000001',
          () => expect(tryParseFixed("1.000001", 6), BigInt.from(1000001)));

      test('should parse 1 as 1000000', () => expect(tryParseFixed("1", 6), BigInt.from(1000000)));

      test(
          'should parse 1. as 1000000', () => expect(tryParseFixed("1.", 6), BigInt.from(1000000)));

      test('should parse 1.1 as 1100000',
          () => expect(tryParseFixed("1.1", 6), BigInt.from(1100000)));

      test('should parse 01.1 as 1100000',
          () => expect(tryParseFixed("01.1", 6), BigInt.from(1100000)));

      test('should parse 1100000 as 11000000',
          () => expect(tryParseFixed("1100000", 1), BigInt.from(11000000)));
    });

    group('tryParseFixed, negative', () {
      test('should parse -1.000001 as -1000001',
          () => expect(tryParseFixed("-1.000001", 6), BigInt.from(-1000001)));

      test('should parse -1 as 1000000',
          () => expect(tryParseFixed("-1", 6), BigInt.from(-1000000)));
    });

    group('tryParseFixed, no leading 0', () {
      test('should parse .000001 as 1', () => expect(tryParseFixed(".000001", 6), BigInt.from(1)));

      test('should parse .00002 as 20', () => expect(tryParseFixed(".00002", 6), BigInt.from(20)));

      test('should parse -.00002 as -20',
          () => expect(tryParseFixed("-.00002", 6), BigInt.from(-20)));
    });

    group('tryParseFixed, truncating excess precision', () {
      test('should truncate one excess digit, not round up',
          () => expect(tryParseFixed("1.1234567", 6), BigInt.from(1123456)));

      test('should truncate many excess digits',
          () => expect(tryParseFixed("320.31402299", 6), BigInt.from(320314022)));

      test('should parse .0000010 as 1',
          () => expect(tryParseFixed(".0000010", 6), BigInt.from(1)));

      test('should truncate the magnitude of a negative value toward zero',
          () => expect(tryParseFixed("-1.9999999", 6), BigInt.from(-1999999)));

      test('should return 0 when the whole fractional part is below the precision',
          () => expect(tryParseFixed("0.0000001", 6), BigInt.zero));
    });

    group('tryParseFixed, return `null`', () {
      test('should parse .000.0010 as null, too many decimal points',
          () => expect(tryParseFixed(".000.0010", 6), isNull));

      test('should parse . as `null`, missing value', () => expect(tryParseFixed(".", 6), isNull));

      test('should parse a non numeric value as `null`',
          () => expect(tryParseFixed("1,11", 6), isNull));
    });
  });
}
