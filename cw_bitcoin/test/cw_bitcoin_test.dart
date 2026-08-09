import 'package:cw_bitcoin/electrum.dart';
import 'package:flutter_test/flutter_test.dart';

class _FeeRateClient extends ElectrumClient {
  _FeeRateClient(this.feesByPriority);

  final Map<int, double> feesByPriority;

  @override
  Future<double> estimatefee({required int p}) async => feesByPriority[p] ?? 0.0;
}

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

  group('ElectrumClient.feeRates', () {
    test('maps p1/p5/p10 estimates to [bottom, middle, top]', () async {
      final client = _FeeRateClient({1: 0.00009, 5: 0.00005, 10: 0.00001});
      expect(await client.feeRates(), [1, 5, 9]);
    });

    test('floors unavailable (-1) estimates to 0, never negative', () async {
      final client = _FeeRateClient({1: -1.0, 5: -1.0, 10: -1.0});
      expect(await client.feeRates(), [0, 0, 0]);
    });

    test('caps extremely large estimates at 2000 sat/vB', () async {
      final client = _FeeRateClient({1: 0.1, 5: 0.00009, 10: 0.00001});
      expect(await client.feeRates(), [1, 9, 2000]);
    });
  });
}
