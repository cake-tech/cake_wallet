import 'package:cw_core/format_fixed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatFixed', () {
    group('formatFixed, no fractional digits and trimming zeros', () {
      test('should format 1000000 into 1',
          () => expect(formatFixed(BigInt.parse("1000000"), 6), '1'));

      test('should format 1000001 into 1.000001',
          () => expect(formatFixed(BigInt.parse("1000001"), 6), '1.000001'));
    });

    group('formatFixed, different fractional digits and trimming zeros', () {
      test(
        'should format 1000001 into 1',
        () => expect(
            formatFixed(BigInt.parse("1000001"), 6, fractionalDigits: 5), '1'),
      );

      test(
        'should format 1000000 into 1, fractionalDigits > decimals',
        () => expect(
            formatFixed(BigInt.parse("1000000"), 6, fractionalDigits: 12), '1'),
      );

      test(
        'should format 1000001 into 1.000001, fractionalDigits > decimals',
        () => expect(
          formatFixed(BigInt.parse("1000001"), 6, fractionalDigits: 12),
          '1.000001',
        ),
      );
    });

    group('formatFixed, less fractional digits and not trimming zeros', () {
      test(
        'should format 1000000 into 1.000000',
        () => expect(
          formatFixed(BigInt.parse("1000000"), 6, trimZeros: false),
          '1.000000',
        ),
      );

      test(
        'should format 1000001 into 1.00000',
        () => expect(
          formatFixed(BigInt.parse("1000001"), 6,
              fractionalDigits: 5, trimZeros: false),
          '1.00000',
        ),
      );

      test(
        'should format 1000000 into 1.000000',
        () => expect(
          formatFixed(BigInt.parse("1000000"), 6,
              fractionalDigits: 12, trimZeros: false),
          '1.000000',
        ),
      );
    });
  });
}
