import 'package:cw_zano/zano_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scales a decimal amount by the token decimals', () {
    expect(ZanoFormatter.parseAmount('1.5'), 1500000000000);
  });

  test('rejects an amount that does not fit in an int', () {
    // 1e20 at 12 decimals is 1e32. toInt() currently returns
    // 9223372036854775807 instead of throwing.
    expect(() => ZanoFormatter.parseAmount('${'1'}${'0' * 20}'), throwsA(isA<ArgumentError>()));
  });
}
