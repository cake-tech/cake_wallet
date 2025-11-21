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
  });
}
