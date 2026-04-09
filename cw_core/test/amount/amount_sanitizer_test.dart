import 'package:cw_core/amount/amount_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smartAmountSanitizer', () {
    test('sanitize british', (){
      final amount = smartAmountSanitizer("1,000.00");
      expect(amount, "1000.00");
    });

    test('sanitize normal', (){
      final amount = smartAmountSanitizer("1.000,00");
      expect(amount, "1000.00");
    });
  });
}
