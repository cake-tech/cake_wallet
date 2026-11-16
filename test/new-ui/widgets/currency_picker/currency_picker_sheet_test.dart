import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_args.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_row.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/currency_picker_sheet.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/multi_network_currency_picker.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/pill_grid.dart";
import "package:cake_wallet/new-ui/widgets/currency_picker/single_network_currency_picker.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  late List<CryptoCurrency> walletPicks;
  late List<CryptoCurrency> otherPicks;
  late bool sheetClosed;

  setUp(() {
    walletPicks = [];
    otherPicks = [];
    sheetClosed = false;
  });

  CurrencyPickerArgs pickerArgs() => CurrencyPickerArgs(
        items: const [CryptoCurrency.xmr],
        selected: CryptoCurrency.xmr,
        filterByNetwork: WalletType.monero,
        useSingleNetworkLayout: true,
        walletName: "Main",
        onSelected: walletPicks.add,
        symbolResolver: (currency) => currency.title,
        otherAssets: CurrencyPickerArgs(
          items: const [
            CryptoCurrency.btc,
            CryptoCurrency.usdterc20,
            CryptoCurrency.usdttrc20,
          ],
          onSelected: otherPicks.add,
          symbolResolver: (currency) => currency.title,
        ),
      );

  Future<void> openPicker(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await CurrencyPickerSheet.show(context: context, args: pickerArgs());
                sheetClosed = true;
              },
              child: const Text("open"),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();
    expect(find.byType(SingleNetworkCurrencyPicker), findsOneWidget);
  }

  Future<void> openOtherAssets(WidgetTester tester) async {
    await tester.tap(find.text(S.current.send_another_asset));
    await tester.pumpAndSettle();
    expect(find.byType(MultiNetworkCurrencyPicker), findsOneWidget);
  }

  Finder rowFor(CryptoCurrency currency) => find
      .byWidgetPredicate((widget) => widget is CurrencyPickerRow && widget.currency == currency)
      .first;

  testWidgets("picking from the wallet list closes the sheet", (tester) async {
    await openPicker(tester);

    await tester.tap(rowFor(CryptoCurrency.xmr));
    await tester.pumpAndSettle();

    expect(walletPicks, [CryptoCurrency.xmr]);
    expect(otherPicks, isEmpty);
    expect(find.byType(CurrencyPickerSheet), findsNothing);
    expect(sheetClosed, isTrue);
  });

  testWidgets("picking another asset closes the whole sheet", (tester) async {
    await openPicker(tester);
    await openOtherAssets(tester);

    await tester.ensureVisible(rowFor(CryptoCurrency.btc));
    await tester.pumpAndSettle();
    await tester.tap(rowFor(CryptoCurrency.btc));
    await tester.pumpAndSettle();

    expect(otherPicks, [CryptoCurrency.btc]);
    expect(walletPicks, isEmpty);
    expect(find.byType(CurrencyPickerSheet), findsNothing);
    expect(sheetClosed, isTrue);
  });

  testWidgets("picking a stablecoin network closes the whole sheet", (tester) async {
    await openPicker(tester);
    await openOtherAssets(tester);

    await tester.tap(find.descendant(of: find.byType(PillGrid), matching: find.text("USDT")));
    await tester.pumpAndSettle();
    await tester.tap(find.text(walletTypeToString(WalletType.tron)));
    await tester.pumpAndSettle();

    expect(otherPicks, [CryptoCurrency.usdttrc20]);
    expect(find.byType(CurrencyPickerSheet), findsNothing);
    expect(sheetClosed, isTrue);
  });

  testWidgets("going back from other assets keeps the wallet list open", (tester) async {
    await openPicker(tester);
    await openOtherAssets(tester);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.byType(SingleNetworkCurrencyPicker), findsOneWidget);
    expect(find.byType(MultiNetworkCurrencyPicker), findsNothing);
    expect(otherPicks, isEmpty);
    expect(sheetClosed, isFalse);
  });
}
