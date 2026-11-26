import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_message_card.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "sheet_test_app.dart";

const signInMessage =
    "app.uniswap.org wants you to sign in with your Ethereum account:\n"
    "0x52908400098527886E0F7030069857D2E4169EE7\n\n"
    "Sign in to Uniswap to continue.\n\n"
    "URI: https://app.uniswap.org\nVersion: 1\nChain ID: 1\n"
    "Nonce: 32891756\nIssued At: 2026-11-26T07:00:00.000Z";

void main() {
  setUpAll(() async {
    S.current = const S();
    await loadSheetFonts();
  });

  testWidgets("renders the title, warnings and every summary row", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("en"),
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [
              WCMessageCard(
                decoded: WCDecodedRequest(
                  actionTitle: "Approve",
                  actionSubtitle: "Permit2",
                  warnings: ["Unlimited approval"],
                  rows: [
                    WCDecodedRow(label: "Token", value: "USD Coin (USDC)"),
                    WCDecodedRow(
                      label: "Amount",
                      value: "Unlimited USDC",
                      kind: WCDecodedRowKind.amount,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("Approve"), findsOneWidget);
    expect(find.text("Permit2"), findsOneWidget);
    expect(find.text("Unlimited approval"), findsOneWidget);
    expect(find.text("USD Coin (USDC)"), findsOneWidget);
    expect(find.text("Unlimited USDC"), findsOneWidget);
  });

  testWidgets("detail rows stay hidden until the toggle is tapped", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("en"),
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [
              WCMessageCard(
                decoded: WCDecodedRequest(
                  actionTitle: "Swap",
                  rows: [WCDecodedRow(label: "Pay", value: "1 SOL")],
                  detailRows: [WCDecodedRow(label: "Instruction 1", value: "Transfer")],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("Instruction 1"), findsNothing);
    await tester.tap(find.text(S.current.wc_show_details));
    await tester.pumpAndSettle();
    expect(find.text("Instruction 1"), findsOneWidget);

    await tester.tap(find.text(S.current.wc_hide_details));
    await tester.pumpAndSettle();
    expect(find.text("Instruction 1"), findsNothing);
  });

  testWidgets("raw payload stays hidden until the toggle is tapped", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("en"),
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [
              WCMessageCard(
                decoded: WCDecodedRequest(actionTitle: "Contract call", rawFallback: "0xdeadbeef"),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("0xdeadbeef"), findsNothing);
    await tester.tap(find.text(S.current.wc_view_raw));
    await tester.pumpAndSettle();
    expect(find.text("0xdeadbeef"), findsOneWidget);
  });

  testWidgets("no toggles render when there is nothing behind them", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("en"),
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [
              WCMessageCard(
                decoded: WCDecodedRequest(
                  actionTitle: "Sign message",
                  rows: [WCDecodedRow(label: "Message", value: "hello")],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(S.current.wc_show_details), findsNothing);
    expect(find.text(S.current.wc_view_raw), findsNothing);
  });

  testWidgets("a fiat line renders beneath its amount", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("en"),
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [
              WCMessageCard(
                decoded: WCDecodedRequest(
                  actionTitle: "Transfer",
                  rows: [
                    WCDecodedRow(
                      label: "Amount",
                      value: "25 USDC",
                      kind: WCDecodedRowKind.amount,
                      fiatValue: "~ 24.99 USD",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("25 USDC"), findsOneWidget);
    expect(find.text("~ 24.99 USD"), findsOneWidget);
  });

  testWidgets("info rows render after the decoded rows", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("en"),
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [
              WCMessageCard(
                decoded: WCDecodedRequest(
                  actionTitle: "Send",
                  rows: [WCDecodedRow(label: "Amount", value: "0.5 ETH")],
                ),
                infoRows: [WCDecodedRow(label: "Method", value: "eth_sendTransaction")],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("eth_sendTransaction"), findsOneWidget);
  });

  group("row layout", () {
    Future<void> pumpRows(WidgetTester tester, Size size, List<WCDecodedRow> rows) async {
      setPhoneSize(tester, size);
      await tester.pumpWidget(
        sheetTestApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: WCMessageCard(
                    decoded: WCDecodedRequest(actionTitle: "Sign message", rows: rows),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (final size in phoneSizes) {
      testWidgets("a sign in message on a $size phone is stacked under its label, full width", (
        tester,
      ) async {
        await pumpRows(tester, size, const [WCDecodedRow(label: "Message", value: signInMessage)]);

        final label = tester.getRect(find.text("Message"));
        final value = tester.getRect(find.byType(SelectableText));
        expect(value.width, size.width - 64);
        expect(value.left, label.left);
        expect(value.top, greaterThan(label.bottom));
        expect(tester.widget<SelectableText>(find.byType(SelectableText)).textAlign, isNull);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets("a short text value stays beside its label", (tester) async {
      await pumpRows(tester, const Size(390, 844), const [
        WCDecodedRow(label: "Message", value: "hello"),
      ]);

      final label = tester.getRect(find.text("Message"));
      final value = tester.getRect(find.byType(SelectableText));
      expect(value.left, greaterThan(label.right));
      expect(value.top, label.top);
    });

    testWidgets("text stacks from 61 characters on, an address of any length never does", (
      tester,
    ) async {
      final atLimit = "a" * 60;
      final overLimit = "b" * 61;
      const address = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6tTR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";
      await pumpRows(tester, const Size(390, 844), [
        WCDecodedRow(label: "At limit", value: atLimit),
        WCDecodedRow(label: "Over limit", value: overLimit),
        const WCDecodedRow(label: "Address", value: address, kind: WCDecodedRowKind.address),
      ]);

      double left(String value) => tester.getRect(find.text(value)).left;
      final labelLeft = tester.getRect(find.text("At limit")).left;

      expect(left(atLimit), greaterThan(labelLeft));
      expect(left(overLimit), labelLeft);
      expect(left(address), greaterThan(labelLeft));
    });
  });
}
