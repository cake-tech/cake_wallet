import 'package:cw_core/amount/amount_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('smartAmountSanitizer', () {
    test('sanitize decimal dot', () {
      final amount = "1,000.00".sanitized();
      expect(amount, "1000.00");
    });

    test('sanitize decimal comma', () {
      final amount = "1.000,00".sanitized();
      expect(amount, "1000.00");
    });

    test('general case', () {
      final amount = "1000.00".sanitized();
      expect(amount, "1000.00");
    });

    test('no decimals', () {
      final amount = "1,000".sanitized();
      expect(amount, "1.000");
    });

    test('no decimals', () {
      final amount = "1.000".sanitized();
      expect(amount, "1.000");
    });
  });
}
