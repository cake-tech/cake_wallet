import 'package:cw_bitcoin/electrum.dart';
import 'package:cw_bitcoin/electrum_transaction_info.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter_test/flutter_test.dart';

ElectrumTransactionInfo _bitcoinTxInfo({int? fee, int? vsize}) => ElectrumTransactionInfo(
      WalletType.bitcoin,
      id: 'txid',
      amount: Money.fromInt(0, CryptoCurrency.btc),
      fee: fee != null ? Money.fromInt(fee, CryptoCurrency.btc) : null,
      direction: TransactionDirection.incoming,
      isPending: false,
      date: DateTime.fromMillisecondsSinceEpoch(0),
      confirmations: 1,
      vsize: vsize,
    );

void main() {
  group('ElectrumTransactionInfo fee rate', () {
    test('computes fee rate as fee / vsize in sat/vB', () {
      expect(_bitcoinTxInfo(fee: 300, vsize: 150).feeRateSatsPerVbyte, 2);
    });

    test('rounds half-up like the displayed fee rate division', () {
      expect(_bitcoinTxInfo(fee: 75, vsize: 10).feeRateSatsPerVbyte, 8);
      expect(_bitcoinTxInfo(fee: 74, vsize: 10).feeRateSatsPerVbyte, 7);
    });

    test('returns null when vsize is unavailable', () {
      expect(_bitcoinTxInfo(fee: 300).feeRateSatsPerVbyte, null);
    });

    test('returns null when fee is unavailable', () {
      expect(_bitcoinTxInfo(vsize: 150).feeRateSatsPerVbyte, null);
    });

    test('returns null for non-positive vsize', () {
      expect(_bitcoinTxInfo(fee: 300, vsize: 0).feeRateSatsPerVbyte, null);
      expect(_bitcoinTxInfo(fee: 300, vsize: -1).feeRateSatsPerVbyte, null);
    });

    test('round-trips vsize through json', () {
      final info = _bitcoinTxInfo(fee: 300, vsize: 150);
      final restored = ElectrumTransactionInfo.fromJson(info.toJson(), WalletType.bitcoin);
      expect(restored.vsize, 150);
      expect(restored.feeRateSatsPerVbyte, 2);
    });

    test('legacy stored records without vsize stay readable', () {
      final legacyJson = _bitcoinTxInfo(fee: 300).toJson()..remove('vsize');
      final restored = ElectrumTransactionInfo.fromJson(legacyJson, WalletType.bitcoin);
      expect(restored.vsize, null);
      expect(restored.fee, Money.fromInt(300, CryptoCurrency.btc));
      expect(restored.feeRateSatsPerVbyte, null);
    });
  });

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
