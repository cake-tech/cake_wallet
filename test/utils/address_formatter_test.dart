import "package:cake_wallet/utils/address_formatter.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

const _btc = "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq";
const _xmr = "44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3Xjrp"
    "DtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A";
const _mweb = "ltcmweb1qqf0kctdmt7xdtnkm2j0mfy2rhr4pl2rwkxq";
const _bch = "bitcoincash:qzm47qz5ue99y9yl4aca7jnz7dwgdenl85jwvdp424";

const _style = TextStyle(color: Colors.black);

/// The stops a screen reader would actually visit, in traversal order.
List<String> _labels(WidgetTester tester) =>
    tester.semantics.simulatedAccessibilityTraversal().map((node) => node.label).toList();

Future<void> _pump(
  WidgetTester tester, {
  required String address,
  WalletType? walletType,
  bool shouldTruncate = false,
}) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AddressFormatter.buildSegmentedAddress(
              address: address,
              walletType: walletType,
              evenTextStyle: _style,
              shouldTruncate: shouldTruncate,
            ),
          ),
        ),
      ),
    );

void main() {
  group("full segmented address", () {
    testWidgets("announces the whole address as one node", (tester) async {
      await _pump(tester, address: _btc);

      expect(_labels(tester), [_btc]);
    });

    testWidgets("the space-separated chunks are not announced", (tester) async {
      await _pump(tester, address: _btc);

      // The RichText is visually chunked, but that must not reach a screen reader.
      expect(find.byType(RichText), findsWidgets);
      expect(find.semantics.byPredicate((node) => node.label.contains(" ")), findsNothing);
    });

    testWidgets("a Monero address (6-char chunks) is announced in full", (tester) async {
      await _pump(tester, address: _xmr, walletType: WalletType.monero);

      expect(_labels(tester), [_xmr]);
    });

    testWidgets("an MWEB address is announced in full", (tester) async {
      await _pump(tester, address: _mweb);

      expect(_labels(tester), [_mweb]);
    });
  });

  group("truncated address", () {
    testWidgets("announces the whole address, never the ellipsis", (tester) async {
      await _pump(tester, address: _btc, shouldTruncate: true);

      expect(_labels(tester), [_btc]);
      expect(find.semantics.byPredicate((node) => node.label.contains("...")), findsNothing);
    });

    testWidgets("a truncated Monero address is announced in full", (tester) async {
      await _pump(tester, address: _xmr, walletType: WalletType.monero, shouldTruncate: true);

      expect(_labels(tester), [_xmr]);
    });

    testWidgets("a truncated MWEB address is announced in full", (tester) async {
      await _pump(tester, address: _mweb, shouldTruncate: true);

      expect(_labels(tester), [_mweb]);
    });

    testWidgets("an address too short to truncate is still announced in full", (tester) async {
      await _pump(tester, address: "abcdefg", shouldTruncate: true);

      expect(_labels(tester), ["abcdefg"]);
    });
  });

  group("special forms", () {
    testWidgets("the bitcoincash: prefix is dropped from the announcement too", (tester) async {
      await _pump(tester, address: _bch);

      // The prefix is stripped for display, so the announced string matches it.
      expect(_labels(tester), [_bch.replaceAll("bitcoincash:", "")]);
    });

    testWidgets("a human-readable name is announced verbatim", (tester) async {
      await _pump(tester, address: "seth@cakewallet.com");

      expect(_labels(tester), ["seth@cakewallet.com"]);
    });
  });
}
