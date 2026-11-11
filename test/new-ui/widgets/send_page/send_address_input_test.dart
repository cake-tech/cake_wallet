import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/locales/locale.dart";
import "package:cake_wallet/new-ui/widgets/send_page/send_address_input.dart";
import "package:cw_core/crypto_currency.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";

const _address = "bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq";

void main() {
  late TextEditingController controller;
  late List<Uri> scanned;
  late int pasteCallbacks;

  setUp(() {
    controller = TextEditingController();
    scanned = [];
    pasteCallbacks = 0;
  });

  Future<void> pumpInput(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: localizationDelegates,
        supportedLocales: S.delegate.supportedLocales,
        home: Scaffold(
          body: NewSendAddressInput(
            addressController: controller,
            selectedCurrency: CryptoCurrency.btc,
            onEditingComplete: () {},
            onURIScanned: scanned.add,
            onPushPasteButton: (_) => pasteCallbacks++,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  void mockClipboard(WidgetTester tester, String text) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == "Clipboard.getData" ? {"text": text} : null,
    );
  }

  testWidgets("typing a URI one character at a time never collapses it", (tester) async {
    await pumpInput(tester);

    const typed = "bitcoin:b";
    for (var i = 1; i <= typed.length; i++) {
      controller.text = typed.substring(0, i);
      await tester.pump();
    }

    expect(controller.text, typed);
    expect(scanned, isEmpty);
  });

  testWidgets("a URI inserted at once collapses to the address and is dispatched",
      (tester) async {
    await pumpInput(tester);

    const uri = "bitcoin:$_address?amount=0.001&pj=https://payjo.in/ABC";
    controller.text = uri;
    await tester.pump();

    expect(controller.text, _address);
    expect(scanned.single.toString(), uri);
  });

  testWidgets("an ERC-681 token transfer is dispatched without replacing the field",
      (tester) async {
    await pumpInput(tester);

    const uri = "ethereum:0xdac17f958d2ee523a2206206994597c13d831ec7@1/transfer"
        "?address=0x8e23ee67d1332ad560396262c48ffbb01f93d052&uint256=1";
    controller.text = uri;
    await tester.pump();

    expect(controller.text, uri);
    expect(scanned.single.toString(), uri);
  });

  testWidgets("pasting a bare address replaces the previous recipient", (tester) async {
    await pumpInput(tester);
    controller.text = "bc1qold";
    await tester.pump();
    mockClipboard(tester, _address);

    await tester.tap(find.bySemanticsLabel(S.current.paste));
    await tester.pump();

    expect(controller.text, _address);
    expect(pasteCallbacks, 1);
    expect(scanned, isEmpty);
  });

  testWidgets("pasting a payment URI fills the address and dispatches the URI",
      (tester) async {
    await pumpInput(tester);
    const uri = "bitcoin:$_address?pj=https://payjo.in/ABC";
    mockClipboard(tester, uri);

    await tester.tap(find.bySemanticsLabel(S.current.paste));
    await tester.pump();

    expect(controller.text, _address);
    expect(scanned.single.toString(), uri);
    expect(pasteCallbacks, 0);
  });
}
