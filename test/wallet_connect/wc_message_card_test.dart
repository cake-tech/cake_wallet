import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_request.dart";
import "package:cake_wallet/src/screens/wallet_connect/decoders/wc_decoded_row.dart";
import "package:cake_wallet/src/screens/wallet_connect/widgets/wc_message_card.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  setUpAll(() {
    S.current = const S();
  });

  testWidgets("renders the title, warnings and every summary row", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale("en"),
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.delegate.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: WCMessageCard(
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
          body: SingleChildScrollView(
            child: WCMessageCard(
              decoded: WCDecodedRequest(
                actionTitle: "Swap",
                rows: [WCDecodedRow(label: "Pay", value: "1 SOL")],
                detailRows: [WCDecodedRow(label: "Instruction 1", value: "Transfer")],
              ),
            ),
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
          body: SingleChildScrollView(
            child: WCMessageCard(
              decoded: WCDecodedRequest(
                actionTitle: "Contract call",
                rawFallback: "0xdeadbeef",
              ),
            ),
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
          body: SingleChildScrollView(
            child: WCMessageCard(
              decoded: WCDecodedRequest(
                actionTitle: "Sign message",
                rows: [WCDecodedRow(label: "Message", value: "hello")],
              ),
            ),
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
          body: SingleChildScrollView(
            child: WCMessageCard(
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
          body: SingleChildScrollView(
            child: WCMessageCard(
              decoded: WCDecodedRequest(
                actionTitle: "Send",
                rows: [WCDecodedRow(label: "Amount", value: "0.5 ETH")],
              ),
              infoRows: [WCDecodedRow(label: "Method", value: "eth_sendTransaction")],
            ),
          ),
        ),
      ),
    );

    expect(find.text("eth_sendTransaction"), findsOneWidget);
  });
}
