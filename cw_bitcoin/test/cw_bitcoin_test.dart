import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lightning matchers', () {
    final RegExp lightningInvoiceRegex =
        RegExp(r'^(lightning:)?(lnbc|lntb|lnbs|lnbcrt)[a-z0-9]+$', caseSensitive: false);

    test('Valid invoice', () {
      final content =
          "lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw508d6qejxtdg4y5r3zarvary0c5xw7kpqdxssqfsqqqyqqqqlgqqqqqeqqjq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgq9qrsgqfsqqqyqqqqlgqqqqqeqqjq9qrsgq";
      expect(lightningInvoiceRegex.hasMatch(content), true);
    });
    test('Valid invoice with prefix', () {
      final content =
          "lightning:lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpuaztrnwngzn3kdzw508d6qejxtdg4y5r3zarvary0c5xw7kpqdxssqfsqqqyqqqqlgqqqqqeqqjq9qrsgq";
      expect(lightningInvoiceRegex.hasMatch(content), true);
    });
    test('Invalid invoice', () {
      final content = "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq"; // This is a Bitcoin address
      expect(lightningInvoiceRegex.hasMatch(content), false);
    });
  });
}
