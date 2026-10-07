import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/utils.dart';
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

  group('dash address classification', () {
    // Dash is P2PKH-only, and its X-prefixed addresses match none of bitcoin_base's
    // hardcoded address regexes, so addressTypeFromStr must special-case DashNetwork
    // rather than fall through to P2wpkhAddress (which throws on Dash).
    const dashAddress = "Xs8xnigGeN1FG9fZfWJFHhJaCg5oxAUmQU";

    test('classifies a dash address as P2PKH', () {
      final address = addressTypeFromStr(dashAddress, DashNetwork.mainnet);

      expect(address, isA<P2pkhAddress>());
      expect(address.toAddress(DashNetwork.mainnet), dashAddress);
    });

    test('derives the electrum scripthash of a dash address', () {
      // Matches the value the cipig ElectrumX server accepts for this address.
      expect(
        scriptHashOfAddress(dashAddress, DashNetwork.mainnet),
        "06c4fee7ad2321d04d96f97ea46104a6f7999269a48fc79f9baf03a4786d30cd",
      );
    });

    test('leaves bitcoin address classification unchanged', () {
      const bitcoinAddress = "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq";

      expect(
        addressTypeFromStr(bitcoinAddress, BitcoinNetwork.mainnet),
        isA<P2wpkhAddress>(),
      );
    });
  });
}
