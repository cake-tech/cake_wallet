import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/cards/balance_card.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/card_design.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/evm_network.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  AddedNetworkCurrency addedNetwork({required bool isManual}) => AddedNetworkCurrency(
        EvmNetwork(
          chainId: 424242,
          name: "Zebra Chain",
          symbol: "ZBR",
          decimals: 18,
          tag: "ZBR",
          rpcUrl: "https://rpc.example",
          isManual: isManual,
        ),
      );

  Future<CakeImageWidget> pumpCornerIcon(WidgetTester tester, CardDesign design) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(body: BalanceCard(width: 320, design: design)),
      ),
    );
    await tester.pump();

    return tester.widget<CakeImageWidget>(
      find.byWidgetPredicate(
        (widget) => widget is CakeImageWidget && widget.imageUrl == design.imagePath,
      ),
    );
  }

  testWidgets("an added network without an icon draws its first letter in a rounded square",
      (tester) async {
    final network = addedNetwork(isManual: false);

    final corner = await pumpCornerIcon(tester, CardDesign.forCurrencyIcon(network));

    expect(corner.imageUrl, "");
    expect(corner.fallbackName, "Zebra Chain");
    expect(corner.isRoundedSquare, isTrue);
    expect(corner.isOutlined, isFalse);
    expect(corner.colorFilter, isNull);
    expect(find.text("Z"), findsOneWidget);
  });

  testWidgets("a manual network corner icon gets the outline", (tester) async {
    final network = addedNetwork(isManual: true);

    final corner = await pumpCornerIcon(tester, CardDesign.forCurrencyIcon(network));

    expect(corner.isOutlined, isTrue);
  });

  testWidgets("a built-in chain corner icon stays a plain tinted svg", (tester) async {
    final corner = await pumpCornerIcon(
      tester,
      CardDesign.forCurrencyIcon(CryptoCurrency.eth).withGradient(CardDesign.gradientBlue),
    );

    expect(corner.imageUrl, "assets/new-ui/balance_card_icons/ethereum.svg");
    expect(corner.fallbackName, isNull);
    expect(corner.isRoundedSquare, isFalse);
    expect(corner.isOutlined, isFalse);
    expect(corner.colorFilter, isNotNull);
  });
}
